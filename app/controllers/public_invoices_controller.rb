class PublicInvoicesController < ApplicationController
  def show
    account_statement =
      AccountStatement.not_deleted.find_by(public_token: params[:public_token])

    if account_statement
      # TODO: add public token for invoice
      invoice = account_statement.business.invoices.find_by(id: params[:invoice_id])
    end

    if account_statement.nil? || invoice.nil?
      render_not_found
    else
      render(
        pdf: "invoice-#{invoice.invoice_number}",
        template: 'pdfs/invoice',
        locals: {
          invoice: invoice
        }
      )
    end
  end
end
