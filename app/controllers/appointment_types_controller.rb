class AppointmentTypesController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, AppointmentType
  end

  before_action :set_appointment_type, only: [:show, :edit, :update, :destroy]

  def index
    @search_query = current_business.appointment_types.not_deleted.ransack(params[:q].try(:to_unsafe_h))

    @appointment_types = @search_query.result
    .order(name: :asc)
    .page(params[:page])
  end

  def show
  end

  def new
    @appointment_type = AppointmentType.new(
      display_on_online_bookings: false,
      practitioner_ids: current_business.practitioners.active.pluck(:id)
    )
  end

  def edit
    if @appointment_type.deleted_at?
      redirect_back fallback_location: appointment_types_url, alert: 'The appointment type is not editable.'
      return
    end
  end

  def create
    @appointment_type = current_business.appointment_types.new(create_appointment_type_params)

    if @appointment_type.save
      redirect_to appointment_type_url(@appointment_type),
                  notice: 'Appointment type was successfully created.'
    else
      flash.now[:alert] = 'Failed to create appointment type. Please check for form errors.'
      render :new
    end
  end

  def update
    if @appointment_type.deleted_at?
      redirect_back fallback_location: appointment_types_url, alert: 'The appointment type is not editable.'
      return
    end

    if @appointment_type.update(update_appointment_type_params)
      redirect_to appointment_type_url(@appointment_type),
                  notice: 'Appointment type was successfully updated.'
    else
      flash.now[:alert] = 'Failed to update appointment type. Please check for form errors.'
      render :edit
    end
  end

  def destroy
    @appointment_type.update_column :deleted_at, Time.current
    DeletedResource.create(
      business: current_business,
      resource: @appointment_type,
      author: current_user,
      deleted_at: Time.current
    )
    redirect_to appointment_types_url,
                notice: 'Appointment type was successfully destroyed.'
  end

  private

  def set_appointment_type
    @appointment_type = current_business.appointment_types.find(params[:id])
  end

  def create_appointment_type_params
    params.require(:appointment_type).permit(
      :name,
      :description,
      :duration,
      :default_treatment_template_id,
      :reminder_enable,
      :display_on_online_bookings,
      :availability_type_id,
      practitioner_ids: [],
      billable_item_ids: []
    )
  end

  def update_appointment_type_params
    params.require(:appointment_type).permit(
      :name,
      :description,
      :duration,
      :default_treatment_template_id,
      :reminder_enable,
      :display_on_online_bookings,
      practitioner_ids: [],
      billable_item_ids: []
    )
  end
end
