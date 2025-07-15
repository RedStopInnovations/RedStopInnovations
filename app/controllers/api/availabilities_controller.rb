module Api
  class AvailabilitiesController < BaseController
    before_action :set_availability, only: [
      :destroy, :update_appointments_order,
      :optimize_route, :send_arrival_times, :change_practitioner,
      :lock_order, :unlock_order, :calculate_route, :send_bulk_sms,
      :update_time
    ]

    def index
      authorize! :read, :calendar

      @availabilities = Calendar.new(current_business).availabilities(
        params[:from_date].to_date,
        params[:to_date].to_date,
        params[:practitioner_ids]
      )
      render status: :ok
    end

    def search_by_date
      practitioner = current_business.practitioners.find(params[:practitioner_id])

      date = params[:date].to_date
      time_range = date.beginning_of_day..date.end_of_day

      query = practitioner.availabilities

      if params[:availability_type_id].present?
        query = query.where(availability_type_id: params[:availability_type_id].to_i)
      else
        query = query.where(
          availability_type_id: [
            AvailabilityType::TYPE_HOME_VISIT_ID,
            AvailabilityType::TYPE_FACILITY_ID,
            AvailabilityType::TYPE_GROUP_APPOINTMENT_ID,
          ]
        )
      end

      @availabilities = query.where(start_time: time_range).load
    end

    def show
      @availability = current_business.
        availabilities.
        includes(
          :practitioner,
          :contacts,
          appointments: [
            :patient, :practitioner, :appointment_type, :invoice,
            :treatment, :arrival, bookings_answers: [:question]
          ]
        ).
        find(params[:id])
    end

    def create
      form = CreateAvailabilityForm.new(
        create_availability_params.merge(business: current_business)
      )

      if form.valid?
        @availability = CreateAvailabilityService.new.call(current_business, form)
        ::Webhook::Worker.perform_later(
          @availability.id,
          WebhookSubscription::AVAILABILITY_CREATED
        )
        render :show, status: :created
      else
        render json: {
                errors: form.errors.full_messages
               },
               status: :unprocessable_entity
      end
    end

    def update
      @availability = current_business.availabilities.find(params[:id])

      # Extract seperate form & service for each type of availability
      if @availability.group_appointment?
        form = UpdateGroupAppointmentAvailabilityForm.new(
          update_group_appointment_availability_params.merge(
            business: current_business,
            availability_id: @availability.id
          )
        )

        if form.valid?
          UpdateGroupAppointmentAvailabilityService.new.call(@availability, form)
          @availability.reload
          render :show, status: :ok
        else
          render json: {
                  errors: form.errors.full_messages
                },
                status: :unprocessable_entity
        end
      else
        form = UpdateAvailabilityForm.new(
          update_availability_params.merge(
            business: current_business,
            availability_id: @availability.id
          )
        )

        if form.valid?
          @availability = UpdateAvailabilityService.new.call(@availability, form)
          render :show, status: :ok
        else
          render json: {
                  errors: form.errors.full_messages
                },
                status: :unprocessable_entity
        end
      end
    end

    def update_time
      form = UpdateAvailabilityTimeForm.new(
        update_availability_time_params.merge(
          availability: @availability
        )
      )

      if form.valid?
        @availability = UpdateAvailabilityTimeService.new.call(@availability, form)
        render :show, status: :ok
      else
        render json: {
                errors: form.errors.full_messages
              },
              status: :unprocessable_entity
      end
    end

    def destroy
      form = DeleteAvailabilityForm.new(delete_params)
      form.availability = @availability

      if form.valid?
        DeleteAvailabilityService.new.call(@availability, form, current_user)
        head :no_content
      else
        render(json: {
            errors: form.errors.full_messages
          },
          status: 422
        )
      end
    end

    def update_appointments_order
      if !@availability.order_locked?
        ids_in_new_order = update_appointment_order_params[:appointment_ids].to_a

        Availability.transaction do
          ids_in_new_order.each_with_index do |id, index|
            @availability.appointments.find(id).update_column :order, index
          end

          if @availability.home_visit?
            HomeVisitRouting::ArrivalCalculate.new.call(@availability.id)
          elsif @availability.facility?
            HomeVisitRouting::FacilityArrivalCalculate.new.call(@availability.id)
          end

          AvailabilityCachedStats.new.update @availability
        end

        if @availability.home_visit? && @availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
          SyncAvailabilityToGoogleCalendarWorker.perform_async(@availability.id)
        end

        head :no_content
      else
        render(
          json: {
            message: 'The appointments order is locked.',
          },
          status: 400
        )
      end
    end

    def send_arrival_times
      # @TODO: send in background
      send_time = Time.current
      send_option = params[:send_option].presence || 'FORCE_ALL'

      @availability.appointments.each do |appointment|
        patient = appointment.patient

        if patient.mobile_formated.present? && appointment.arrival && appointment.arrival.arrival_at?
          perform_send =
            if send_option == 'FORCE_ALL'
              true
            elsif send_option == 'SKIP_REMINDER_DISABLED'
              patient.reminder_enable?
            end

          if perform_send
            # @TODO: move to a job
            sms_content = build_sms_arrival_time_content(appointment)
            com = Communication.create!(
              business_id: current_business.id,
              message_type: Communication::TYPE_SMS,
              category: 'appointment_arrival_time',
              recipient: patient,
              linked_patient_id: patient.id,
              message: sms_content,
              source: appointment
            )

            begin
              com_delivery = CommunicationDelivery.new(
                communication_id: com.id,
                recipient: patient.mobile_formated,
                tracking_id: SecureRandom.base58(32),
                last_tried_at: send_time,
                provider_id: CommunicationDelivery::PROVIDER_ID_TWILIO,
                status: CommunicationDelivery::STATUS_SCHEDULED
              )
              com_delivery.save

              twilio_message = Twilio::REST::Client.new.messages.create(
                messaging_service_sid: ENV['TWILIO_SMS_SERVICE_ID'],
                body: sms_content,
                to: patient.mobile_formated,
                status_callback: twilio_sms_delivery_hook_url(tracking_id: com_delivery.tracking_id)
              )

              com_delivery.provider_resource_id = twilio_message.sid
              com_delivery.provider_delivery_status = twilio_message.status
              com_delivery.status = CommunicationDelivery::STATUS_PROCESSED
              appointment.arrival.update_attribute :sent_at, send_time

              billing_item = SubscriptionBillingService.new.create_sms_billing_item(
                current_business, 'Send appointment arrival time to client', appointment
              )

              UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)

              head :no_content
            rescue => e
              provider_metadata = {}
              com_delivery.status = CommunicationDelivery::STATUS_ERROR

              case e
              when Twilio::REST::ServerError
                com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_SERVICE_ERROR
                com_delivery.error_message = e.message
                provider_metadata['error_code'] = e.code
                provider_metadata['error_message'] = e.message
              when Twilio::REST::RequestError
                provider_metadata['error_code'] = e.code
                provider_metadata['error_message'] = e.message

                case e.code.to_s
                when '21211', '21214', '21612', '21614' # Invalid 'To' Phone Number, 'To' phone number cannot be reached
                  com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
                  com_delivery.error_message = e.message
                when '21212', '21408', '51001', '51002', '14107', '21603', '21606', '21611', '21618'
                  com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
                else
                  com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_UNKNOWN
                end
              else
                com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
              end

              com_delivery.provider_metadata = provider_metadata

              unless com_delivery.error_type == CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
                Sentry.capture_exception(e)
              end
            ensure
              if com_delivery
                com_delivery.save
              end
            end
          end
        end
      end

      head :no_content
    end

    def send_bulk_sms
      if !current_business.in_trial_period? && current_business.subscription_credit_card_added?
        form_request = SendAvailabilityBulkSmsForm.new(params.permit(
          :send_option,
          :content,
          :communication_category
        ))

        ahoy_track_once 'Use send bulk SMS feature'

        if form_request.valid?
          result = SendAvailabilityBulkSmsService.new.call(current_business, @availability, form_request)
          if result.success
            render(json: {
                message: 'The messages has been sent'
              }
            )
          else
            render(json: {
                message: 'An error has occurred. Sorry for the inconvenience.'
              },
              status: 500
            )
          end
        else
          render(json: {
              errors: form_request.errors.full_messages,
              message: 'Failed to send SMS. Please check validation errors.'
            },
            status: 422
          )
        end
      else
        render(json: {
            message: 'This feature is not available on your company account.'
          },
          status: 400
        )
      end
    end

    def optimize_route
      if !@availability.order_locked?
        ahoy_track_once 'Use optimize route feature'
        HomeVisitRouting::Optimizer.new.call(@availability.id)
        if @availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
          SyncAvailabilityToGoogleCalendarWorker.perform_async(@availability.id)
        end

        AvailabilityCachedStats.new.update @availability

        head :no_content
      else
        render(
          json: {
            message: 'The appointments order is locked.',
          },
          status: 400
        )
      end
    end

    def calculate_route
      ahoy_track_once 'Use calculate route feature'
      HomeVisitRouting::ArrivalCalculate.new.call(@availability.id)

      if @availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(@availability.id)
      end

      AvailabilityCachedStats.new.update @availability

      @availability.reload

      render :show
    end

    def change_practitioner
      form = ChangeAvailabilityPractitionerForm.new(
        change_practitioner_params.merge(
          availability: @availability,
          business: current_business
        )
      )

      if form.valid?
        result = ChangeAvailablityPractitionerService.new.call(@availability, form)
        if result.success
          @availability = result.availability
          render :show, status: :ok
        else
          render(
            json: {
              message: 'An error has occurred'
            },
            status: 500
          )
        end
      else
        render(
          json: {
            errors: form.errors.full_messages
          },
          status: :unprocessable_entity
        )
      end
    end

    def single_home_visit
      form = SingleHomeVisitAvailabilityForm.new(
        create_single_home_visit_params.merge(
          business: current_business
        )
      )

      if form.valid?
        result = CreateSingleHomeVisitAvailabilityService.new.call(
          current_business, form
        )
        if result.success
          @availability = result.availability
          render :show, status: :ok
        else
          render(
            json: {
              message: 'An error has occurred'
            },
            status: 500
          )
        end
      else
        render(
          json: {
            errors: form.errors.full_messages
          },
          status: :unprocessable_entity
        )
      end
    end

    def non_billable
      form = CreateNonBillableAvailabilityForm.new(
        create_non_billable_params.merge(
          business: current_business
        )
      )

      if form.valid?
        result = CreateNonBillableAvailabilityService.new.call(current_business, form)
        if result.success
          @availability = result.availability
          render :show, status: :ok
        else
          render(
            json: {
              message: 'An error has occurred'
            },
            status: 500
          )
        end
      else
        render(
          json: {
            errors: form.errors.full_messages
          },
          status: :unprocessable_entity
        )
      end
    end

    def group_appointment
      form = CreateGroupAppointmentAvailabilityForm.new(
        create_group_appointment_availability_params.merge(
          business: current_business
        )
      )

      if form.valid?
        result = CreateGroupAppointmentAvailabilityService.new.call(current_business, form)
        if result.success
          @availability = result.availability
          render :show, status: :ok
        else
          render(
            json: {
              message: 'An error has occurred'
            },
            status: 500
          )
        end
      else
        render(
          json: {
            errors: form.errors.full_messages
          },
          status: :unprocessable_entity
        )
      end
    end

    def lock_order
      @availability.update_columns(
        order_locked: true,
        order_locked_by: current_user.id,
        updated_at: Time.current
      )

      head :no_content
    end

    def unlock_order
      @availability.update_columns(
        order_locked: false,
        order_locked_by: nil,
        updated_at: Time.current
      )

      head :no_content
    end

    private

    def set_availability
      @availability = current_business.availabilities.find(params[:id])
    end

    def update_appointment_order_params
      params.permit(appointment_ids: [])
    end

    def build_sms_arrival_time_content(appointment)
      patient = appointment.patient
      practitioner = appointment.practitioner
      business = practitioner.business
      template = business.get_communication_template('appointment_arrival_time')
      result = Letter::Renderer.new(patient, template).render([
        business,
        practitioner,
        appointment
      ])
      result.content
    end

    def create_single_home_visit_params
      params.require(:availability).permit(
        :start_time,
        :end_time,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :patient_id,
        :appointment_type_id,
        :patient_case_id,
        :practitioner_id,
        :repeat_type,
        :repeat_interval,
        :repeat_total
      )
    end

    def create_non_billable_params
      params.require(:availability).permit(
        :name,
        :description,
        :availability_subtype_id,
        :contact_id,
        :start_time,
        :end_time,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :practitioner_id,
        :repeat_type,
        :repeat_interval,
        :repeat_total
      )
    end

    def create_group_appointment_availability_params
      params.require(:availability).permit(
        :practitioner_id,
        :contact_id,
        :appointment_type_id,
        :description,
        :start_time,
        :end_time,
        :max_appointment,

        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country
      )
    end

    def update_availability_params
      params.require(:availability).permit(
        :start_time,
        :end_time,
        :max_appointment,
        :service_radius,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :repeat,
        :allow_online_bookings,
        :apply_to_future_repeats,
        :contact_id,
        :name,
        :description,
        :availability_subtype_id
      )
    end

    def update_availability_time_params
      params.require(:availability).permit(
        :start_time,
        :end_time,
        :apply_to_future_repeats,
      )
    end

    def update_group_appointment_availability_params
      params.require(:availability).permit(
        :start_time,
        :end_time,
        :max_appointment,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :contact_id,
        :description,
        :group_appointment_type_id
      )
    end

    def create_availability_params
      params.require(:availability).permit(
        :start_time,
        :end_time,
        :max_appointment,
        :service_radius,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :practitioner_id,
        :allow_online_bookings,
        :availability_type_id,
        :contact_id,
        :repeat_type,
        :repeat_interval,
        :repeat_total
      )
    end

    def delete_params
      params.permit(
        :delete_future_repeats,
        :notify_cancel_appointment
      )
    end

    def change_practitioner_params
      params.permit(
        :practitioner_id,
        :apply_to_future_repeats
      )
    end
  end
end
