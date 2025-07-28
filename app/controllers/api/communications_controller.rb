module Api
  class CommunicationsController < BaseController

    # Build content from given template and parameters
    def build_content
      template_id = params[:template_id]
      template = current_business.get_communication_template(template_id)
      template_params = params.fetch(:template_params)

      # TODO: check template enabled?
      if template
        # TODO: refactor this
        case template.template_id
        when CommunicationTemplate::TEMPLATE_ID_PRACTITIONER_ON_ROUTE_SMS
          appointment = current_business.appointments.where(id: template_params.fetch(:appointment_id)).first

          if appointment
            practitioner = appointment.practitioner
            patient = appointment.patient

            result = Letter::Renderer.new(patient, template).render([
              current_business,
              practitioner,
              appointment
            ].compact)

            render json: {
              content: result.content
            }
          else
            render(
              json: {
                message: 'The appointment does not exist'
              },
              status: 400
            )
          end
        else
        end
      else
        render(
          json: {
            message: 'The template does not exist'
          },
          status: 400
        )
      end
    end

    def send_patient_message
      form = SendPatientMessageForm.new(
        params.permit(
          :patient_id,
          :content,
          :communication_category,
          :source_id,
          :source_type,
        ).merge(business: current_business)
      )

      if form.valid?
        patient = current_business.patients.find(form.patient_id)
        rejected_error =
          if !patient.mobile_formated.present?
            'The client mobile number is not present or invalid'
          end

        if !rejected_error
          # Check if SMS is enabled for the business
          unless current_business.sms_settings&.enabled?
            rejected_error = 'The SMS feature is not available on your account'
          end
        end

        if rejected_error
          render(
            json: {
              message: "Could not send messsage, error: #{rejected_error}"
            },
            status: 400
          )
        else
          begin
            SendPatientMessageService.new.call(current_business, form, current_user)
            render(
              json: {
                message: 'The messsage has been sent successfully.'
              }
            )
          rescue SendPatientMessageService::FeatureNotAvailable => e
            render(
              json: {
                message: e.message
              },
              status: 400
            )
          rescue => e
            Sentry.capture_exception(e)
            render(
              json: {
                message: 'An error has occurred. Failed to send the message.'
              },
              status: 500
            )
          end
        end
      else
        render(
          json: { errors: form.errors.full_messages },
          status: 422
        )
      end
    end

    def sms_conversations
      page = (params[:page] || 1).to_i
      latest_com_query = Patient.joins('INNER JOIN communications ON communications.linked_patient_id = patients.id')
        .where('patients.business_id': current_business.id)
        .where('communications.message_type': Communication::TYPE_SMS)
        .group('patients.id')
        .order('MAX(communications.id) DESC')
        .select('MAX(communications.id) AS latest_communication_id')

      communications = Communication.where(id: latest_com_query)
        .includes(:linked_patient)
        .order(created_at: :desc)
        .page(page)

      conversations = communications.map do |comm|
        {
          patient_id: comm.linked_patient.id,
          patient_name: comm.linked_patient.full_name,
          patient_mobile: comm.linked_patient.mobile_formated,
          last_message_id: comm.id,
          last_message: comm.message,
          last_message_direction: comm.direction,
          last_message_at: comm.created_at,
          read: comm.read
        }
      end

      render json: {
        conversations: conversations,
        pagination: {
          current_page: page,
          total_count: communications.total_count,
          total_pages: communications.total_pages,
        }
      }
    end

    def unread_conversations_count
      render json: { count: count_unread_conversations }
    end

    def patient_sms_conversations
      patient_id = params[:patient_id]
      page = (params[:page] || 1).to_i

      patient = current_business.patients.find(patient_id)

      messages = current_business
        .communications
        .where(linked_patient_id: patient_id, message_type: Communication::TYPE_SMS)
        .order(created_at: :desc)
        .page(page)

      conversations = messages.map do |message|
        {
          id: message.id,
          message: message.message,
          direction: message.direction,
          created_at: message.created_at,
          from: message.from
        }
      end

      render json: {
        patient: {
          id: patient.id,
          name: patient.full_name,
          mobile_formated: patient.mobile_formated,
        },
        messages: conversations,
        pagination: {
          current_page: messages.current_page,
          total_count: messages.total_count,
          total_pages: messages.total_pages,
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Patient not found' }, status: 404
    end

    def send_message
      patient_id = params[:patient_id]
      message_content = params[:message]

      # Check if 2-way sms is enabled for the business
      unless current_business.sms_settings&.enabled?
        render json: { message: 'The SMS feature is not available on your account' }, status: 400
        return
      end

      # Validate patient belongs to current business
      patient = current_business.patients.find(patient_id)

      # Validate message content
      if message_content.blank?
        render json: { message: 'Message content cannot be empty' }, status: 400
        return
      else
        message_content = message_content.strip
        if message_content.length > 320
          render json: { message: 'Message content exceeds maximum length of 320 characters' }, status: 400
          return
        end
      end

      # Check if patient has a valid mobile number
      unless patient.mobile_formated.present?
        render json: { message: 'Patient does not have a valid mobile number' }, status: 400
        return
      end

      begin
        # Create the communication record
        com = current_business.communications.create!(
          category: 'General',
          linked_patient: patient,
          message: message_content.strip,
          message_type: Communication::TYPE_SMS,
          direction: Communication::DIRECTION_OUTBOUND,
          from: current_business.sms_settings&.twilio_number || 'System',
          recipient: patient
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

          status_callback_url =
            if Rails.env.production?
              twilio_sms_delivery_hook_url(tracking_id: com_delivery.tracking_id)
            end

          twilio_message_from = current_business.sms_settings.enabled_two_way? ? current_business.sms_settings.twilio_number : ENV['TWILIO_MESSAGE_DEFAULT_FROM']

          twilio_message = Twilio::REST::Client.new.messages.create(
            from: twilio_message_from,
            body: com.message,
            to: patient.mobile_formated,
            status_callback: status_callback_url
          )

          com_delivery.provider_resource_id = twilio_message.sid
          com_delivery.provider_delivery_status = twilio_message.status
          com_delivery.status = CommunicationDelivery::STATUS_PROCESSED

          billing_item = SubscriptionBillingService.new.create_sms_billing_item(
            current_business, 'Send message to client'
          )

          UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)

          render json: {
            message: com.message,
            created_at: com.created_at
          }
        rescue => e
          provider_metadata = {}
          com_delivery.status = CommunicationDelivery::STATUS_ERROR
          provider_metadata['error_code'] = e.code
          provider_metadata['error_message'] = e.message

          com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
          com_delivery.provider_metadata = provider_metadata

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

      rescue => e
        Sentry.capture_exception(e)
        render json: {
          message: 'Failed to send message: ' + e.message
        }, status: 500
      end

    rescue ActiveRecord::RecordNotFound
      render json: { message: 'Patient not found' }, status: 404
    end

    def mark_as_read_conversation
      patient_id = params[:patient_id]

      patient = current_business.patients.find(patient_id)

      # Mark all SMS communications with this patient as read
      current_business
        .communications
        .where(
          linked_patient_id: patient_id,
          message_type: Communication::TYPE_SMS
        )
        .where(read: false)
        .update_all(read: true)

      render json: {
        message: 'Conversation marked as read',
      }

    rescue ActiveRecord::RecordNotFound
      render json: { message: 'Patient not found' }, status: 404
    end

    private

    def count_unread_conversations
      current_business
        .communications
        .where(
          message_type: Communication::TYPE_SMS,
          direction: Communication::DIRECTION_INBOUND,
          read: false
        )
        .distinct
        .count(:linked_patient_id)
    end
  end
end