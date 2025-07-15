class ContactCommunicationsController < ApplicationController
  include HasABusiness

  before_action :find_contact

  before_action do
    authorize! :read, Communication
  end

  def index
    @search_query = Communication.where(recipient: @contact).
      ransack(params[:q].try(:to_unsafe_h))

    @communications = @search_query.
      result.
      includes(:linked_patient, :source, :delivery).
      order(created_at: :desc).
      page(params[:page])
  end

  def show
    @communication = Communication.where(recipient: @contact).find(params[:id])
  end

  private

  def find_contact
    @contact = current_business.contacts.find(params[:contact_id])
  end
end
