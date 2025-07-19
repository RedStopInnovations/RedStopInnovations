class InvoicesController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, Invoice
  end

  before_action :set_invoice, only: [
    :show, :edit, :update, :deliver, :destroy,
    :send_medipass_request, :send_to_contacts,
    :resend_medipass_request,
    :payments, :preview_medipass_payment_request,
    :modal_email_others,
    :preview_dva_payment,
    :send_dva_payment,
    :preview_bulk_bill_payment,
    :send_bulk_bill_payment,
    :mark_as_sent,
    :enable_outstanding_reminder,
    :disable_outstanding_reminder,
    :activity_log
  ]

  before_action :not_allow_if_voided, only: [
    :edit, :update, :deliver, :destroy,
    :send_medipass_request, :send_to_contacts,
    :resend_medipass_request,
    :payments, :preview_medipass_payment_request,
    :modal_email_others,
    :preview_dva_payment,
    :send_dva_payment,
    :preview_bulk_bill_payment,
    :send_bulk_bill_payment,
    :mark_as_sent,
    :enable_outstanding_reminder,
    :disable_outstanding_reminder,
  ]

  def index
    @search_query = invoices_scoped_query_for_current_user.ransack(params[:q].try(:to_unsafe_h))

    @invoices = @search_query
                .result
                .preload(
                  :patient, :appointment, :invoice_to_contact, patient_case: [:case_type], created_version: [:author]
                )
                .order('issue_date DESC, created_at DESC')
                .page(params[:page])
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render(
          pdf: "invoice-#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          show_as_html: params.key?('__debug__'),
          locals: {
            invoice: @invoice
          },
          disable_javascript: true
        )
      end
      format.json
    end
  end

  def activity_log
    @invoice_activities = InvoiceActivity.fetch @invoice
    render layout: false
  end

  def new
  end

  def create
    create_params = create_invoice_params

    @invoice = current_business.invoices.new(create_params)
    @invoice.issue_date = Date.current

    # @TODO: add form class for validation
    if @invoice.valid?
      created_invoice = CreateInvoiceService.new.call(current_business, create_params)

      if params[:send_after_create] == true
        SendInvoiceService.new.call(created_invoice, current_user)
      end

      respond_to do |f|
        f.json do
          render(
            json: {
              invoice: created_invoice
            },
            status: 201
          )
        end

        f.html do
          redirect_to new_payment_path(invoice_id: created_invoice.id),
                  notice: 'The invoice was successfully created.'
        end
      end
    else
      respond_to do |f|
        f.html do
          render :new
        end
        f.json do
          render(
            json: {
              errors: @invoice.errors.full_messages,
              message: 'Failed to create invoice. Please check for form errors.'
            },
            status: 422
          )
        end
      end
    end
  end

  def edit
    authorize! :edit, @invoice
  end

  def update
    authorize! :edit, @invoice

    update_params = @invoice.paid? ? update_paid_invoice_params : update_invoice_params
    @invoice.assign_attributes update_params

    if @invoice.valid?

      if @invoice.paid?
        @invoice.save!(validate: false)
      else
        @invoice.reload
        UpdateInvoiceService.new.call(@invoice, update_params)
      end

      @invoice.reload

      respond_to do |f|
        f.json do
          render(
            json: {
              invoice: @invoice
            },
            status: 200
          )
        end

        f.html do
          redirect_to invoice_path(@invoice.id),
                  notice: 'The invoice was successfully updated.'
        end
      end
    else
      respond_to do |f|
        f.html do
          render :edit
        end
        f.json do
          render(
            json: {
              errors: @invoice.errors.full_messages,
              message: 'Failed to updae invoice. Please check for form errors.'
            },
            status: 422
          )
        end
      end
    end
  end

  def destroy
    authorize! :destroy, @invoice

    if @invoice.paid?
      flash[:alert] = "Can not void a paid invoice."
    else
      @invoice.destroy_by_author(current_user)
      flash[:notice] = 'The invoice was successfully voided.'
    end

    redirect_to invoices_url
  end

  def deliver
    patient = @invoice.patient

    if patient.email?
      # if current_business.subscription_credit_card_added?
        InvoiceMailer.invoice_mail(@invoice).deliver_later
        send_ts = Time.current
        @invoice.update_columns(
          last_send_patient_at: send_ts,
          last_send_at: send_ts
        )
      # end
      flash[:notice] = 'The invoice has been sent to client'
    else
      flash[:alert] = 'The client has not an email address'
    end

    redirect_back fallback_location: (params[:redirect] || invoice_url(@invoice))
  end

  def send_to_contacts
    form = SendOthersForm.new(
      send_others_params.merge(business: current_business)
    )

    if form.valid?
      if current_business.subscription_credit_card_added?
        SendInvoiceToOthersService.new.call(@invoice, current_user, form)
      end
      flash[:notice] = 'The invoice has been successfully sent.'
    else
      flash[:alert] = "Could not send invoice. Error: #{form.errors.full_messages.first}."
    end

    redirect_back fallback_location: (params[:redirect] || invoice_url(@invoice))
  end

  def payments
    @payment_allocations = @invoice.payment_allocations.includes(:payment)
  end

  def send_medipass_request
    ahoy_track_once 'Use Medipass payment / Send request'

    begin
      MedipassPaymentService.new.call(@invoice)
      flash[:notice] = 'A Medipass payment request has been sent to the client.'
      rescue MedipassPaymentService::Exception => e
        @error = e.message
      end

    respond_to do |f|
      f.html do
        if @error
          flash[:alert] = @error
        end

        redirect_to new_payment_url(invoice_id: @invoice.id)
      end
      f.js
    end
  end

  def resend_medipass_request
    ahoy_track_once 'Use Medipass payment / Resend'

    begin
      ResendMedipassPaymentService.new.call(@invoice)
      flash[:notice] = 'Payment request has been sent to the client.'
    rescue ResendMedipassPaymentService::Exception => e
      flash[:alert] = e.message
    end
    redirect_to invoice_url(@invoice)
  end

  def preview_medipass_payment_request
    ahoy_track_once 'Use Medipass payment / Preview'

    if current_business.medipass_payment_available?
      @payment_availability = Medipass::PaymentAvailability.new(@invoice)

      unless @payment_availability.errors.any?
        @quote = @invoice.medipass_quote
        if @quote.nil?
          begin
            @quote = CreateMedipassQuote.new.call(
              @invoice,
              @invoice.patient.medipass_member_id
            )
          rescue Medipass::ApiException => e
            @quote_error = e.message
          end
        end
      end
    end
  end

  def preview_dva_payment
    ahoy_track_once 'Use DVA payment / Preview'

    unless Rails.env.production?
      @payment_availability = Claiming::Dva::PaymentAvailability.new(@invoice)
    end
  end

  def send_dva_payment
    ahoy_track_once 'Use DVA payment / Send'

    begin
      Claiming::Dva::CreateClaim.new.call(@invoice)
      redirect_to invoice_url(@invoice),
                  notice: 'The claim has been successfully created.'
    rescue => e
      Sentry.capture_exception(e)
      redirect_back fallback_location: invoice_url(@invoice),
                    alert: "An error has occurred."
    end
  end

  def send_bulk_bill_payment
    ahoy_track_once 'Use bulk bill payment / Send'

    begin
      Claiming::BulkBill::CreateClaim.new.call(@invoice)
      redirect_to invoice_url(@invoice),
                  notice: 'The claim has been successfully created.'
    rescue => e
      Sentry.capture_exception(e)
      redirect_back fallback_location: invoice_url(@invoice),
                    alert: "An error has occurred."
    end
  end

  def preview_bulk_bill_payment
    ahoy_track_once 'Use bulk bill payment / Preview'

    unless Rails.env.production?
      @payment_availability = Claiming::BulkBill::PaymentAvailability.new(@invoice)
    end
  end

  def modal_email_others
    @send_other_form = SendOthersForm.new
    if params[:contact_ids].present? && params[:contact_ids].is_a?(Array)
      @send_other_form.contact_ids = current_business.contacts.where(id: params[:contact_ids]).pluck(:id)
    end
    render 'invoices/_modal_email_others', locals: { invoice: @invoice }, layout: false
  end

  def mark_as_sent
    @invoice.update_column :last_send_at, Time.current
    redirect_back fallback_location: invoice_url(@invoice),
                  notice: 'The invoice is marked as sent.'
  end

  def enable_outstanding_reminder
    reminder_template = current_business.get_communication_template('outstanding_invoice_reminder')

    if reminder_template && reminder_template.enabled?
      cur_outstanding_reminder_info = @invoice.outstanding_reminder || {}
      cur_outstanding_reminder_info['enable'] = true

      global_reminder_settings = reminder_template.settings || {
        'outstanding_days' => 14
      }

      if !cur_outstanding_reminder_info['scheduled_job_id'] || (
        cur_outstanding_reminder_info['scheduled_job_perform_at'].present? && Time.at(cur_outstanding_reminder_info['scheduled_job_perform_at']).past?
        )
        first_reminder_at = @invoice.created_at + global_reminder_settings['outstanding_days'].days
        if first_reminder_at.future?
          job_jid = OutstandingInvoiceReminderWorker.perform_at(first_reminder_at, @invoice.id)
          cur_outstanding_reminder_info['scheduled_job_id'] = job_jid
          cur_outstanding_reminder_info['scheduled_job_perform_at'] = first_reminder_at.to_i
        end
      end

      @invoice.update_column :outstanding_reminder, cur_outstanding_reminder_info
    end

    redirect_back fallback_location: invoice_url(@invoice),
                  notice: 'The automatic outstanding remminder has been enabled.'
  end

  def disable_outstanding_reminder
    reminder_template = current_business.get_communication_template('outstanding_invoice_reminder')

    if reminder_template && reminder_template.enabled?
      cur_outstanding_reminder_info = @invoice.outstanding_reminder || {}
      cur_outstanding_reminder_info['enable'] = false

      @invoice.update_column :outstanding_reminder, cur_outstanding_reminder_info
    end

    redirect_back fallback_location: invoice_url(@invoice),
                  notice: 'The automatic outstanding remminder has been disabled.'
  end

  def modal_bulk_create_from_uninvoiced_appointments
    ahoy_track_once 'Use bulk create invoices for uninvoiced appointments'

    @appointments = current_business.appointments
      .where(id: params[:appointment_ids])
      .includes(:invoice, :patient, :practitioner, appointment_type: [billable_items: :pricing_contacts])
      .order(start_time: :asc)
      .to_a

    render layout: false
  end

  def bulk_create_from_uninvoiced_appointments
    ahoy_track_once 'Use bulk create invoices for uninvoiced appointments'
    authorize! :create, Invoice

    form = BulkCreateInvoicesFromUninvoicedAppointmentsForm.new(
      params.permit(invoices: [
        :appointment_id,
        :send_after_create,
        :patient_case_id
      ]).to_h.merge(business: current_business)
    )

    if form.valid?
      created_invoices = BulkCreateInvoicesFromUninvoicedAppointmentsService.new.call(current_business, form, current_user)

      render(
        json: {
          invoices: created_invoices
        },
        status: 201
      )
    else
      render(
        json: {
          errors: form.errors.full_messages,
          message: 'Failed to create invoices. Please check validation errors.'
        },
        status: 422
      )
    end
  end

  def bulk_send_outstanding_reminder
    authorize! :manage, Invoice
    ahoy_track_once 'Use bulk send outstanding invoice reminders'

    if params[:invoice_ids].present? && params[:invoice_ids].is_a?(Array)
      BulkSendOutstandingInvoiceReminderService.new.call(current_business, params[:invoice_ids], current_user)
      redirect_back fallback_location: reports_outstanding_invoices_path,
                    notice: 'The reminders has been sent.'
    else
      redirect_back fallback_location: reports_outstanding_invoices_path,
                    alert: 'The request is invalid.'
    end
  end

  private

  def send_others_params
    params.permit(:message, contact_ids: [], emails: [])
  end

  def set_invoice
    @invoice = current_business.invoices.with_deleted.find(params[:id])
  end

  def not_allow_if_voided
    if @invoice.deleted_at?
      redirect_back fallback_location: invoice_url(@invoice),
                    alert: 'The action is not allowed as the invoiced was voided.'
    end
  end

  def create_invoice_params
    params.require(:invoice).permit(
      :patient_id,
      :notes,
      :message,
      :appointment_id,
      :patient_case_id,
      :invoice_to_contact_id,
      :task_id,
      items_attributes: [
        :invoiceable_id,
        :invoiceable_type,
        :quantity,
        :unit_price,
        :tax_name,
        :tax_rate,
        :tax_id
      ]
    )
  end

  def update_invoice_params
    params.require(:invoice).permit(
      :notes,
      :message,
      :appointment_id,
      :patient_case_id,
      :invoice_to_contact_id,
      :task_id,
      items_attributes: [
        :id,
        :invoiceable_id,
        :invoiceable_type,
        :quantity,
        :unit_price,
        :_destroy
      ]
    )
  end

  def update_paid_invoice_params
    params.require(:invoice).permit(
      :notes,
      :message,
      :patient_case_id
    )
  end

  def not_allow_if_fully_paid
    if @invoice.paid?
      redirect_back fallback_location: invoice_url(@invoice),
                    alert: 'The action is not allowed as the invoiced was fully paid.'
    end
  end

  def invoices_scoped_query_for_current_user
    query_scope =
      if [
        User::ADMINISTRATOR_ROLE, User::SUPERVISOR_ROLE, User::RECEPTIONIST_ROLE, User::RESTRICTED_SUPERVISOR_ROLE
      ].include?(current_user.role)
        current_business.invoices
      elsif current_user.is_practitioner?
        current_business.invoices.where(practitioner_id: current_user.practitioner.id)
      else
        Invoice.none
      end

    query_scope
  end
end
