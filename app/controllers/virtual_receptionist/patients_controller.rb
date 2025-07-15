module VirtualReceptionist
  class PatientsController < BaseController
    def search
      keyword = params[:s].to_s.presence

      patients =
        if keyword
          current_business.patients
            .not_archived
            .ransack(full_name_cont: keyword)
            .result
            .limit(5)
            .order(full_name: :asc)
        else
          []
        end

      render json: {
        patients: patients.as_json(only: [
            :id, :first_name, :last_name, :full_name, :dob, :city, :state, :address1, :address2, :postcode
          ])
        }
    end

    def future_appointments_list
      @patient = current_business.patients.find(params[:id])
      @appointments = @patient.appointments.not_cancelled.where('start_time > ?', Time.current).order(start_time: :asc).to_a

      render layout: false
    end

    def cancel_appointment
      patient = current_business.patients.find(params[:id])
      appointment = patient.appointments.not_cancelled.where('start_time > ?', Time.current).find_by(id: params[:appointment_id])

      if appointment
        CancelAppointmentService.new.call(current_business, appointment, current_user)
        flash[:notice] = 'The appointment has been succesfully cancelled'
      else
        flash[:alert] = 'The appointment not found or not in state that can be cancelled'
      end

      redirect_back fallback_location: virtual_receptionist_dashboard_url
    end
  end
end