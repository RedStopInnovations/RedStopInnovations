class PaymentsController < ApplicationController
  include HasABusiness

  before_action :set_payment, only: [
    :show, :edit, :update, :destroy
  ]

  before_action :not_allow_if_voided, only: [
    :edit,
    :update,
    :destroy
  ]

  def index
    authorize! :read, Payment

    @payments = current_business.payments.
      includes(:patient, payment_allocations: :invoice).
      order('payment_date DESC, id DESC').
      page(params[:page])
  end

  def show
    authorize! :read, Payment

    @payment_allocations = @payment.payment_allocations.includes(:invoice)
    respond_to do |f|
      f.html
      f.json do
        render json: {
          payment: @payment.as_json(
            include: [ :patient, payment_allocations: { include: :invoice } ]
          )
        }
      end
    end
  end

  def new
    authorize! :create, Payment

    @payment = Payment.new

    if params[:appointment_id] && current_business.appointments.exists?(id: params[:appointment_id])
      appointment = current_business.appointments.find params[:appointment_id]
      @payment.patient_id = appointment.patient_id
    end

    if params[:invoice_id] && !current_business.invoices.exists?(id: params[:invoice_id])
      flash[:alert] = 'The requested invoice does not exist or has been voided'
      redirect_back fallback_location: new_payment_url
    end
  end

  def bulk
    authorize! :create, Payment
    ahoy_track_once 'Use bulk create payments'
  end

  def bulk_create
    authorize! :create, Payment
    ahoy_track_once 'Use bulk create payments'

    form = BulkCreatePaymentsForm.new(
      params.permit(payments: [:invoice_id, :payment_method, :payment_date]).merge(business: current_business)
    )

    if form.valid?
      created_payments = BulkCreatePaymentsService.new.call(current_business, form, current_user)

      render(
        json: {
          payments: created_payments.as_json(include: :payment_allocations)
        },
        status: 201
      )
    else
      render(
        json: {
          errors: form.errors.full_messages,
          message: 'Failed to create payments. Please check validation errors.'
        },
        status: 422
      )
    end
  end

  def edit
    authorize! :update, Payment

    unless @payment.editable?
      redirect_to payment_url(@payment), alert: 'The payment is not editable.'
    end
  end

  def create
    authorize! :create, Payment

    @payment_form = CreatePaymentForm.new(
      create_payment_params.merge(business: current_business)
    )
    @payment_form.business = current_business

    respond_to do |f|
      flash[:notice] = 'Payment was successfully created.'
      f.json do
        if @payment_form.valid?
          result = CreatePaymentService.new.call(current_business, @payment_form)
          render json: {
            payment: result.payment
          }
        else
          render(
            json: {
              errors: @payment_form.errors.full_messages
            },
            status: 422
          )
        end
      end
    end
  end

  def update
    authorize! :update, Payment

    @payment_form = UpdatePaymentForm.new(
      update_payment_params.merge(business: current_business)
    )

    respond_to do |f|
      flash[:notice] = 'Payment was successfully updated.'
      f.json do
        if @payment_form.valid?
          result = UpdatePaymentService.new.call(
            current_business,
            @payment,
            @payment_form
          )
          render json: {
            payment: result.payment
          }
        else
          render(
            json: {
              errors: @payment_form.errors.full_messages
            },
            status: 422
          )
        end
      end
    end
  end

  def destroy
    authorize! :destroy, @payment
    DeletePaymentService.new.call(current_business, @payment, current_user)
    redirect_to payments_url,
                notice: 'Payment was successfully deleted.'
  end

  def pre_stripe_payment
    if params[:patient_id]
      @target_patient = current_business.patients.find(params[:patient_id])
    end

    if params[:invoice_id]
      @target_invoice = current_business.invoices.find(params[:invoice_id])
      @target_patient = @target_invoice.patient
    end

    respond_to do |f|
      f.js do
        if current_business.stripe_payment_available?
          render 'payments/stripe/show_modal_payment'
        else
          render 'payments/stripe/feature_not_active_error'
        end
      end
    end
  end

  def stripe_payment
    authorize! :create, Payment

    form = FormStripePayment.new(stripe_payment_params.merge(
      business: current_business
    ))
    if form.valid?
      begin
        result = InvoiceStripePayment::PayMultiple.new.call(current_business, form)
        if result.success
          flash[:notice] = 'The payment has been successfully made.'
          render(
            json: {
              message: 'The payment has been successfully made.',
              payment: result.payment
            },
            status: 201
          )
        else
          render(
            json: { message: "Cannot process the payment. Error: #{ result.error }" },
            status: 422
          )
        end
      rescue => e
        Sentry.capture_exception(e)
        render(
          json: { message: 'An server error has occurred. Sorry for the inconvenience.' },
          status: 500
        )
      end
    else
      render(
        json: {
          errors: form.errors.full_messages
        },
        status: 422
      )
    end
  end

  private

  def not_allow_if_voided
    if @payment.deleted_at?
      redirect_back fallback_location: payment_url(@payment),
                    alert: 'The action is not allowed as the payment was voided.'
    end
  end

  def set_payment
    @payment = current_business.payments.with_deleted.find(params[:id])
  end

  def create_payment_params
    params.require(:payment).permit(
      :patient_id,
      :payment_date,
      :cash,
      :medicare,
      :workcover,
      :dva,
      :direct_deposit,
      :cheque,
      :other,
      payment_allocations: [
        :amount,
        :invoice_id
      ]
    )
  end

  def update_payment_params
    params.require(:payment).permit(
      :payment_date,
      :cash,
      :medicare,
      :workcover,
      :dva,
      :direct_deposit,
      :cheque,
      :other,
      payment_allocations: [
        :amount,
        :invoice_id
      ]
    )
  end

  def stripe_payment_params
    params.permit(
      :patient_id,
      :use_current_card,
      :stripe_token,
      :save_card,
      invoice_ids: [],
    )
  end
end
