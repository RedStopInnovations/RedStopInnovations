module Admin
  class AppointmentsController < BaseController
    before_action :set_business

    def create
      appt_params = create_appointment_params
      avail = @business.availabilities.find(appt_params.delete(:availability_id))

      @appointment = Appointment.new(create_appointment_params)
      @appointment.assign_attributes(
        availability_id: avail.id,
        start_time: avail.start_time,
        end_time: avail.end_time,
        practitioner_id: avail.practitioner_id
      )

      if @appointment.save
        render :show
      else
        render json: {
                errors: @appointment.errors.full_messages
               },
               status: :unprocessable_entity
      end
    end

    def update
      @appointment = @business.appointments.find(params[:id])
      if @appointment.update(update_appointment_params)
        render :show
      else
        render json: {
                 errors: @appointment.errors.full_messages
               },
               status: :unprocessable_entity
      end
    end

    def destroy
      @appointment = @business.appointments.find(params[:id])

      @appointment.destroy
      head :no_content
    end

    private

    def set_business
      @business = Business.find(params[:business_id])
    end

    def create_appointment_params
      params.require(:appointment).permit(
        :notes,
        :patient_id,
        :appointment_type_id,
        :availability_id
      )
    end

    def update_appointment_params
      params.require(:appointment).permit(
        :notes,
        :patient_id,
        :appointment_type_id
      )
    end
  end
end
