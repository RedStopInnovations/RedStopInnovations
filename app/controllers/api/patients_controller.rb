module Api
  class PatientsController < BaseController
    def show
      authorize! :read, Patient
      @patient = current_business.patients.find(params[:id])
    end

    def search
      authorize! :read, Patient

      keyword = params[:s].to_s.presence

      @patients =
        if keyword
          current_business.patients.not_archived.
            ransack(full_name_or_email_cont: keyword).
            result.
            limit(params[:limit] || 10).
            order(full_name: :asc)
        else
          []
        end
    end

    def create
      authorize! :create, Patient

      create_patient_form = CreatePatientForm.new(create_patient_params)

      if create_patient_form.valid?
        @patient = CreatePatientService.new.call(current_business, create_patient_form, current_user)
        respond_to do |f|
          f.json do
            render :show
          end
        end
      else
      respond_to do |f|
        f.json do
          render(
            json: {
              errors: create_patient_form.errors.full_messages
            },
            status: :unprocessable_entity
          )
        end
      end
      end
    end

    def patient_cases
      @patient = current_business.patients.find(params[:id])

      @patient_cases = @patient.patient_cases
        .includes(:case_type, :practitioner)
        .order(status: :desc, created_at: :desc)
    end

    def appointments
      @patient = current_business.patients.find(params[:id])

      @appointments = @patient.appointments
        .includes(:appointment_type, practitioner: :user)
        .order(start_time: :desc)
    end

    def recent_invoices
      @patient = current_business.patients.find(params[:id])

      @invoices = @patient.invoices.order(issue_date: :desc).limit(params[:limit].presence || 5)
    end

    def invoice_to_contacts
      @patient = current_business.patients.find(params[:id])

      @contacts = @patient.invoice_to_contacts
    end

    def payment_methods
      @patient = current_business.patients.find(params[:id])
    end

    def associated_contacts
      @patient = current_business.patients.find(params[:id])

      @associated_contacts = @patient.patient_contacts.includes(:contact).order('contacts.full_name')
    end

    private

    def create_patient_params
      params.require(:patient).permit(
        :first_name,
        :last_name,
        :phone,
        :mobile,
        :email,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :dob,
        :gender,
        :reminder_enable,
        :general_info,
        :next_of_kin,
        :nationality,
        :aboriginal_status,
        :spoken_languages,
        :accepted_privacy_policy
      )
    end
  end
end
