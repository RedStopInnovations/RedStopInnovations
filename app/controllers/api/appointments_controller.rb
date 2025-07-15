module Api
  class AppointmentsController < BaseController
    before_action :find_appointment, only: [
      :show, :update, :destroy, :update_status, :cancel, :send_review_request,
      :attendance_proofs, :create_attendance_proof, :destroy_attendance_proof,
      :mark_confirmed, :mark_unconfirmed,
      :send_arrival_time
    ]

    def show
    end

    def create
      appt_params = create_appointment_params
      form = CreateAppointmentForm.new(appt_params)
      if form.valid?
        begin
          @appointment = CreateAppointmentService.new.call(current_business, form)
          practitioner = @appointment.practitioner
          render :show
        rescue CreateAppointmentService::Error => e
          render json: {
                   message: "Cound not create appointment, error: #{e.message}"
                 },
                 status: :unprocessable_entity
        end
      else
        render json: {
                errors: form.errors.full_messages,
                message: 'Failed to create appointment. Please check for form errors.'
               },
               status: :unprocessable_entity
      end
    end

    def update
      form = UpdateAppointmentForm.new(update_appointment_params.merge(id: @appointment.id))
      if form.valid?
        begin
          @appointment = UpdateAppointmentService.new.call(current_business, @appointment, form)
          render :show
        rescue UpdateAppointmentService::Error => e
          render json: {
                   message: "Cound not update appointment, error: #{e.message}"
                 },
                 status: :unprocessable_entity
        end
      else
        render json: {
                errors: form.errors.full_messages,
                message: 'Failed to update appointment. Please check for form errors.'
               },
               status: :unprocessable_entity
      end
    end

    def destroy
      DeleteAppointmentService.new.call(current_business, @appointment, current_user)
      head :no_content
    end

    def send_review_request
      begin
        SendReviewRequestService.new.call(@appointment)
        render(
          json: { message: "A review request has been sent to the client." },
        )
      rescue SendReviewRequestService::Exception => e
        render(
          json: { message: e.message },
          status: :bad_request
        )
      end
    end

    def update_status
      @appointment.update!(update_status_params)

      if @appointment.status_completed?
        SubscriptionBillingService.new.bill_appointment(
          current_business,
          @appointment.id,
          SubscriptionBilling::TRIGGER_TYPE_COMPLETED
        )
      end
    end

    def mark_confirmed
      @appointment.is_confirmed = true
      @appointment.save!(
        validate: false
      )
      render(json: {
        message: 'The appointment has been marked as confirmed'
      })
    end

    def mark_unconfirmed
      @appointment.is_confirmed = false
      @appointment.save!(
        validate: false
      )

      render(json: {
        message: 'The appointment has been marked as confirmed'
      })
    end


    def cancel
      CancelAppointmentService.new.call(current_business, @appointment, current_user)
      head :no_content
    end

    def creates
      _params = create_appointments_params
      form = CreateAppointmentsForm.new(_params.merge(business: current_business))

      if form.valid?
        begin
          @appointments = CreateAppointmentsService.new.call(current_business, form)
        rescue CreateAppointmentsService::Error => e
          render json: {
                   message: "Cound not create appointment, error: #{e.message}"
                 },
                 status: :unprocessable_entity
        end
      else
        render json: {
                errors: form.errors.full_messages,
                message: 'Failed to create appointment. Please check for form errors.'
               },
               status: :unprocessable_entity
      end
    end

    def attendance_proofs
      @attendance_proofs = @appointment.attendance_proofs
    end

    def create_attendance_proof
      form = UploadAttendanceProofForm.new(create_attendance_proof_params)
      form.appointment = @appointment

      if form.valid?
        @attendance_proofs = @appointment.attendance_proofs.attach(create_attendance_proof_params[:file])

        render json: {
                message: "Uploaded successfully."
              }
      else
        render(
          json: {
            message: "Validation error: #{form.errors.full_messages.first}"
          },
          status: :unprocessable_entity
        )
      end
    end

    def destroy_attendance_proof
      attachment = @appointment.attendance_proofs.find(params[:attendance_proof_id])
      if attachment
        attachment.purge
        render json: {
               message: "Delete successfully."
             }
      end
    end

    def send_arrival_time
      patient = @appointment.patient

      rejected_error =
        if !patient.mobile_formated.present?
          'The client mobile number is present or not valid format'
        elsif !(@appointment.arrival && @appointment.arrival.arrival_at?)
          'The arrival time of the appointment is not available.'
        end

      if rejected_error
        render(
          json: {
            message: "Cound not sent arrival time. Reason: #{rejected_error}"
          },
          status: 400
        )
      else
        # @TODO: move to a job
        sms_content = build_sms_arrival_time_content(@appointment)
        com = Communication.create!(
          business_id: current_business.id,
          message_type: Communication::TYPE_SMS,
          category: 'appointment_arrival_time',
          recipient: patient,
          linked_patient_id: patient.id,
          message: sms_content,
          source: @appointment
        )

        begin
          com_delivery = CommunicationDelivery.new(
            communication_id: com.id,
            recipient: patient.mobile_formated,
            tracking_id: SecureRandom.base58(32),
            last_tried_at: Time.current,
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

          @appointment.arrival.update_attribute :sent_at, Time.current

          billing_item = SubscriptionBillingService.new.create_sms_billing_item(
            current_business, 'Send appointment arrival time to client', @appointment
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

          render(
            json: {
              message: "An error has occurred. Sorry for the inconvenience. #{e.message}"
            },
            status: 500
          )
        ensure
          if com_delivery
            com_delivery.save
          end
        end

      end
    end

    private

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

    def find_appointment
      @appointment = current_business.appointments.find(params[:id])
    end

    def bulk_create_params
      params.permit(
        :availability_id,
        :appointment_type_id,
        patient_ids: []
      )
    end

    def create_appointment_params
      params.require(:appointment).permit(
        :patient_id,
        :appointment_type_id,
        :availability_id,
        :notes,
        :skip_service_area_restriction,
        :break_times
      )
    end

    def create_appointments_params
      params.permit(
        :patient_id,
        :appointment_type_id,
        :patient_case_id,
        :notes,
        availability_ids: [],
      )
    end

    def update_appointment_params
      params.require(:appointment).permit(
        :availability_id,
        :appointment_type_id,
        :notes,
        :skip_service_area_restriction,
        :break_times,
        :patient_case_id
      )
    end

    def update_status_params
      params.required(:appointment).permit(:status)
    end

    def create_attendance_proof_params
      params.permit(
        :file
      )
    end
  end
end
