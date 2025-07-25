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
            'The client mobile number is present or not valid format'
          end

        if rejected_error
          render(
            json: {
              message: "Cound not send messsage, error: #{rejected_error}"
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
        .where('patients.business_id': 1)
        .where('communications.message_type': Communication::TYPE_SMS)
        .group('patients.id')
        .order('MAX(communications.id) DESC')
        .select('MAX(communications.id) AS latest_communication_id')

      communications = Communication.where(id: latest_com_query)
        .includes(:linked_patient)
        .page(page)

      conversations = communications.map do |comm|
        {
          patient_id: comm.linked_patient.id,
          patient_name: comm.linked_patient.full_name,
          patient_mobile: comm.linked_patient.mobile_formated,
          last_message: comm.message,
          last_message_direction: comm.direction,
          last_message_at: comm.created_at
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
          name: patient.full_name
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
  end
end