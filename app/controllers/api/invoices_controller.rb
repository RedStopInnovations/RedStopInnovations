module Api
  class InvoicesController < BaseController
    def search

      @invoices = current_business.invoices.
            ransack(invoice_number_or_patient_full_name_cont: params[:s].to_s.presence).
            result.
            includes(:patient).
            limit(params[:limit] || 10).
            order(id: :desc)

      render json: {
        invoices: @invoices.as_json(include: :patient)
      }
    end

    def outstanding_search
      @invoices = current_business.invoices
        .not_paid
        .ransack(invoice_number_or_patient_full_name_cont: params[:s].to_s.presence)
        .result
        .includes(:patient)
        .limit(params[:limit] || 10)
        .order(id: :desc)

      render json: {
        invoices: @invoices.as_json(include: [:patient, :invoice_to_contact])
      }
    end

    def show
      @invoice = current_business.invoices.with_deleted.find(params[:id])
    end
  end
end
