class CommunicationsController < ApplicationController
  include HasABusiness

  before_action :set_communication, only: [:show]

  def index
    authorize! :manage, Communication

    respond_to do |f|
      f.html do
        @search_query = current_business.
          communications.
          ransack(params[:q].try(:to_unsafe_h))

        @communications = @search_query.
          result.
          includes(:recipient, :source, :delivery).
          order(created_at: :desc).
          page(params[:page])
      end

      f.csv do
        authorize! :export, Communication
        export = Export::Communications.make(current_business, parse_export_csv_communications_options)
        send_data export.to_csv, filename: "messages_export_#{Time.current.strftime('%Y%m%d')}.csv"
      end
    end
  end

  def show
    authorize! :read, Communication
  end

  private

  def set_communication
    @communication = current_business.communications.find(params[:id])
  end

  def parse_export_csv_communications_options
    ranksack_query = params[:q].try(:to_unsafe_h)
    options_h = {}

    if ranksack_query[:category_eq].present?
      options_h[:category] = ranksack_query[:category_eq]
    end

    if ranksack_query[:message_type_eq].present?
      options_h[:message_type] = ranksack_query[:message_type_eq]
    end

    if ranksack_query[:delivery_status_eq].present? && [CommunicationDelivery::STATUS_DELIVERED, CommunicationDelivery::STATUS_ERROR].include?(ranksack_query[:delivery_status_eq])
      options_h[:delivery_status] = ranksack_query[:delivery_status_eq]
    end

    Export::Communications::Options.new options_h
  end
end
