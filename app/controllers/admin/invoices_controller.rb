module Admin
  class InvoicesController < BaseController
    before_action do
      authorize! :manage, Invoice
    end
    before_action :set_invoice, only: [:show]

    def index
      @search_query = Invoice.ransack(params[:q].try(:to_unsafe_h))

      @invoices = @search_query.
                  result.
                  includes(:business, :patient, :payments, :appointment).
                  order(id: :desc).
                  page(params[:page])
    end

    def show
    respond_to do |format|
      format.html
      format.pdf do
        @business = @invoice.business
        @patient = @invoice.patient
        render pdf: "invoice-#{@invoice.id}",
               template: 'pdfs/invoice',
               locals: {
                 invoice: @invoice,
                 business: @business,
                 patient: @patient
               }
      end
    end
    end

    private

    def set_invoice
      @invoice = Invoice.find(params[:id])
    end
  end
end
