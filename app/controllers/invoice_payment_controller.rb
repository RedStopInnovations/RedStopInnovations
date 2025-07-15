class InvoicePaymentController < ApplicationController
  layout 'frontend/layouts/minimal'

  before_action :find_invoice
  before_action :check_stripe_payment_availability, only: [:process_payment]

  def show
  end

  def process_payment
    if params[:stripe_token].blank?
      redirect_back fallback_location: root_url, alert: 'Bad request'
    else
      patient = @invoice.patient
      business = @invoice.business
      begin
        result = InvoiceStripePayment::PayWithCard.new.call(
          business,
          @invoice,
          params[:stripe_token]
        )
        if result.success
          redirect_back fallback_location: root_url,
                      notice: "The invoice has been successfully paid."
        else
          redirect_back fallback_location: root_url,
                      alert: "An error has occurred: #{ result.error }"
        end
      rescue => e
        Sentry.capture_exception(e)
        redirect_back fallback_location: root_url,
                      alert: 'An server error has occurred. Sorry for the inconvenience.'
      end
    end
  end

  private

  def find_invoice
    token = params[:token]
    @invoice = Invoice.find_by(public_token: token)
  end

  def check_stripe_payment_availability
    if @invoice.nil? || !@invoice.business.stripe_payment_available?
      redirect_to root_url
    end
  end
end
