class PatientCommunicationsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient
  before_action :authorize_patient_access

  before_action do
    authorize! :read, Communication
  end

  def index
    @search_query = Communication.
      where(recipient: @patient).
      or(
        Communication.where(linked_patient_id: @patient.id)
      ).
      ransack(params[:q].try(:to_unsafe_h))

    @communications = @search_query.
      result.
      includes(:recipient, :source, :delivery).
      order(created_at: :desc).
      page(params[:page])
  end

  def show
    @communication = Communication.where(
        recipient_type: 'Patient',
        recipient_id:  @patient.id
      ).
      or(
        Communication.where(linked_patient_id: @patient.id)
      ).find(params[:id])
  end

  private

  def set_patient
    @patient = current_business.patients.find(params[:patient_id])
  end
end
