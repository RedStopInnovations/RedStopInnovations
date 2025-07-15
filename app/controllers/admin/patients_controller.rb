module Admin
  class PatientsController < BaseController

    before_action :set_patient, only: [
      :show, :edit, :update, :invoices, :payments, :appointments
    ]

    def index
      @search_query = patient_scope.includes(:business).
                      ransack(params[:q].try(:to_unsafe_h))
      @patients = @search_query.
                  result.
                  order(id: :desc).
                  page(params[:page])

      respond_to do |format|
        format.html
        format.csv { send_data @patients.to_csv }
      end
    end

    def show
      @patient = Patient.find(params[:id])
    end

    def edit
    end

    def update
      if @patient.update(patient_params)
        redirect_to admin_patient_url(@patient),
                    notice: 'Patient was successfully updated.'
      else
        render :edit
      end
    end

    def invoices
      @invoices = @patient.invoices.order(id: :desc).page(params[:page])
    end

    def payments
      @payments = @patient.payments.order(id: :desc).page(params[:page])
    end

    def appointments
      @appointments = @patient.appointments.order(end_time: :desc).page(params[:page])
    end

    private

    def patient_scope
      current_admin_user.patient_scope
    end

    def set_patient
      @patient = patient_scope.find(params[:id])
    end

    def patient_params
      params.require(:patient).permit(
        :first_name,
        :last_name,
        :phone,
        :mobile,
        :website,
        :fax,
        :email,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :dob,
        :gender,
        :general_info,
        :reminder_enable,
        contact_ids: []
      )
    end
  end
end
