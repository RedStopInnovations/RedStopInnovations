class ContactAccountStatementsController < ApplicationController
  include HasABusiness
  before_action do
    authorize! :read, AccountStatement
  end

  before_action :find_contact
  before_action :find_account_statement,
                only: [
                  :show,
                  :send_to_contact,
                  :regenerate,
                  :destroy
                ]

  def index
    @statement_filter = parse_statement_filter
    result = Statement::ContactAccountStatementBuilder.new(
      @contact,
      @statement_filter
    ).result

    @appointments = result[:appointments]
    @invoices = result[:invoices]
    @payments = result[:payments]
    @patients = Patient.unscoped.where(id: @invoices.map(&:patient_id).uniq).to_a
  end

  def published
    @account_statements = @contact.
      account_statements.
      not_deleted.
      order(id: :desc).
      page(params[:page])
  end

  def publish
    # @TODO: move to service class
    @statement_filter = parse_statement_filter
    account_statement = AccountStatement.new(
      source: @contact,
      business: current_business,
      start_date: @statement_filter.start_date,
      end_date: @statement_filter.end_date,
      options: @statement_filter.to_h.slice(*%i(type invoice_status patient_id)).compact
    )
    AccountStatement.transaction do
      account_statement.save!(validate: false)

      Statement::ContactAccountStatementBuilder.new(
        @contact,
        @statement_filter
      ).result.values.flatten.each do |item|
        account_statement.items.create!(
          source: item
        )
      end

      pdf_html = Statement::PdfBuilder.build(account_statement)
      account_statement.pdf = Extensions::FakeFileIo.new("account_statement.pdf", pdf_html)
      account_statement.save!(validate: false)
    end
    redirect_to published_contact_account_statements_url(@contact),
                notice: 'Statement has been published successfully.'
  end

  def show
    respond_to do |f|
      f.pdf do
        if @account_statement.pdf.file.exists?
          file_name = "#{@contact.business_name.parameterize}__account_statement_#{@account_statement.number}.pdf"
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

      f.html {
        @received_payments = Payment.joins(:invoices)
          .includes(payment_allocations: :invoice)
          .where(invoices: {id: @account_statement.invoices.pluck(:id)})
          .group('payments.id')
          .order(payment_date: :desc)
      }
    end
  end

  def send_to_contact
    if @contact.email.present?
      send_ts = Time.current

      com = current_business.communications.create(
        message_type: Communication::TYPE_EMAIL,
        recipient: @contact,
        category: 'account_statement_send',
        source: @account_statement
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: @contact.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: send_ts,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      ContactAccountStatementMailer.send_to_contact(
        @account_statement, sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later

      @account_statement.invoices.update_all(
        last_send_at: send_ts
      )
      @account_statement.update_column :last_send_at, send_ts

      flash[:notice] = 'The account statement has been sent to contact.'
    else
      flash[:alert] = 'The contact has not an email adddress.'
    end

    redirect_back fallback_location: published_contact_account_statements_url(@contact)
  end

  def destroy
    @account_statement.update_column :deleted_at, Time.current
    DeletedResource.create(
      business: current_business,
      resource: @account_statement,
      author: current_user,
      deleted_at: Time.current
    )
    redirect_to published_contact_account_statements_url(@contact),
                notice: 'The account statement has been successfully deleted.'
  end

  def regenerate
    @account_statement.pdf = Extensions::FakeFileIo.new("account_statement.pdf", Statement::PdfBuilder.build(@account_statement))
    @account_statement.save!(validate: false)

    redirect_back fallback_location: contact_account_statement_url(@contact, @account_statement),
                notice: 'The statement PDF has been successfully updated.'
  end

  private

  def find_contact
    @contact = current_business.contacts.find(params[:contact_id])
  end

  def find_account_statement
    @account_statement = @contact.account_statements.find params[:id]
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

    if params[:patient_id].present? && @contact.patients.exists?(id: params[:patient_id])
      filter_attrs[:patient_id] = params[:patient_id]
    end

    Statement::Filter.new(filter_attrs)
  end
end
