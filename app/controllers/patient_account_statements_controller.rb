class PatientAccountStatementsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :find_patient, :authorize_patient_access
  before_action :find_account_statement,
                only: [
                  :show,
                  :send_to_patient,
                  :pre_send_to_contacts,
                  :send_to_contacts,
                  :regenerate,
                  :destroy
                ]

  before_action do
    authorize! :read, AccountStatement
  end

  def index
    @statement_filter = parse_statement_filter
    result = Statement::PatientAccountStatementBuilder.new(
      @patient,
      @statement_filter
    ).result

    @appointments = result[:appointments]
    @invoices = result[:invoices]
    @payments = result[:payments]
  end

  def published
    @account_statements = @patient.
      account_statements.
      not_deleted.
      order(id: :desc).
      page(params[:page])
  end

  def publish
    @statement_filter = parse_statement_filter
    ApplicationRecord.transaction do
      account_statement = AccountStatement.new(
        source: @patient,
        business: current_business,
        start_date: @statement_filter.start_date,
        end_date: @statement_filter.end_date,
        options: @statement_filter.to_h.slice(*%i(type invoice_status)).compact
      )

      account_statement.save!(validate: false)

      Statement::PatientAccountStatementBuilder.new(
        @patient,
        @statement_filter
      ).result.values.flatten.each do |item|
        account_statement.items.create!(
          source: item
        )
      end

      pdf_html = Statement::PdfBuilder.build(account_statement)
      account_statement.pdf = Extensions::FakeFileIo.new("account_statement_#{account_statement.number}.pdf", pdf_html)
      account_statement.save!(validate: false)
    end

    redirect_to published_patient_account_statements_url,
            notice: 'Statement has been published successfully.'
  end

  def show
    respond_to do |f|
      f.pdf do
        if @account_statement.pdf.file.exists?
          file_name = "#{@patient.full_name.parameterize}__account_statement_#{@account_statement.number}.pdf"
          send_data(
            @account_statement.pdf.file.read,
            filename: file_name,
            type: "application/pdf",
            disposition: 'inline',
            stream: true,
            buffer_size: 4096
          )
        else
          head 404
        end
      end
      f.html do
        @received_payments = Payment.joins(:invoices)
          .includes(payment_allocations: :invoice)
          .where(invoices: {id: @account_statement.invoices.pluck(:id)})
          .group('payments.id')
          .order(payment_date: :desc)
      end
    end
  end

  def send_to_patient
    if @patient.email.present?
      send_ts = Time.current
      @account_statement.invoices.update_all(
        last_send_at: send_ts,
        last_send_patient_at: send_ts
      )
      @account_statement.update_column :last_send_at, send_ts

      com = current_business.communications.create(
        message_type: Communication::TYPE_EMAIL,
        linked_patient_id: @patient.id,
        recipient: @patient,
        category: 'account_statement_send',
        source: @account_statement
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: @patient.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: send_ts,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      PatientAccountStatementMailer.send_to_patient(
        @account_statement, sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later

      flash[:notice] = 'The account statement has been successfully sent.'
    else
      flash[:alert] = 'The client has not an email adddress.'
    end

    redirect_back fallback_location: published_patient_account_statements_url
  end

  def send_to_contacts
    form = SendOthersForm.new(
      send_to_others_params.merge(business: current_business)
    )

    if form.valid?
      if current_business.subscription_credit_card_added?
        SendAccountStatementToOthersService.new.call(@account_statement, form)
      end
      flash[:notice] = 'The account statement has been successfully sent.'
    else
      flash[:alert] = "Could not send account statement. Error: #{form.errors.full_messages.first}"
    end

    redirect_back fallback_location: published_patient_account_statements_url
  end

  def destroy
    @account_statement.update_column :deleted_at, Time.current
    DeletedResource.create(
      business: current_business,
      resource: @account_statement,
      author: current_user,
      associated_patient_id: @patient.id,
      deleted_at: Time.current
    )
    redirect_to published_patient_account_statements_url,
                notice: 'The account statement has been successfully deleted.'
  end

  def regenerate
    @account_statement.pdf = Extensions::FakeFileIo.new("account_statement.pdf", Statement::PdfBuilder.build(@account_statement))
    @account_statement.save!(validate: false)

    redirect_back fallback_location: patient_account_statement_url(@patient, @account_statement),
                notice: 'The statement PDF has been successfully updated.'
  end

  private

  def find_patient
    @patient = current_business.patients.find(params[:patient_id])
  end

  def find_account_statement
    @account_statement = @patient.account_statements.find_by id: params[:id]
    if @account_statement.nil?
      respond_to do |f|
        f.html {
          redirect_to published_patient_account_statements_url,
                alert: 'The account statement does not exist or deleted.'
        }
        f.pdf {
          head :not_found
        }
      end
    end

  end

  def parse_statement_filter
    filter_attrs = {}

    if params[:start_date].present? && params[:end_date].present?
      filter_attrs[:start_date] = params[:start_date].to_date
      filter_attrs[:end_date] = params[:end_date].to_date
    else
      filter_attrs[:start_date] = Date.current.beginning_of_month
      filter_attrs[:end_date] = Date.current
    end

    if params[:type].present?
      filter_attrs[:type] = params[:type]
    else
      filter_attrs[:type] = 'Activity'
    end

    if params[:invoice_status].present?
      filter_attrs[:invoice_status] = params[:invoice_status]
    end

    Statement::Filter.new(filter_attrs)
  end

  def send_to_others_params
    params.permit(:message, contact_ids: [], emails: [])
  end
end
