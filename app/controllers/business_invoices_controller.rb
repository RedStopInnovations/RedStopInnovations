class BusinessInvoicesController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, :settings
  end

  # def index
  #   @business_invoices = current_business.
  #                           business_invoices.
  #                           not_deleted.
  #                           order(issue_date: :desc).
  #                           page(params[:page])
  # end

  def show
    @business_invoice = current_business.business_invoices.not_deleted.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render(
          pdf: "business-invoice-#{@business_invoice.id}",
          template: 'pdfs/business_invoice',
          locals: {
            business_invoice: @business_invoice
          }
        )
      end
    end
  end

  def billed_items
    @business_invoice = current_business.business_invoices.not_deleted.find(params[:id])
    @subscription_billings = SubscriptionBilling.where(
        business_invoice_id: @business_invoice.id
      ).
      includes(appointment: [:practitioner, :patient]).
      order(created_at: :asc).
      page(params[:page]).
      per(50)
  end
end
