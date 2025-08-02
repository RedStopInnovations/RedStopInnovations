class InvoiceBatchesController < ApplicationController
  include HasABusiness
  before_action :set_invoice_batch, only: [:show, :invoices, :send_email, :destroy]

  def index
    @invoice_batches = current_business.invoice_batches
      .includes(:author)
      .order(created_at: :desc)
      .page(params[:page])
  end

  def show
  end

  def new
  end

  def create
    create_batch_params = params.require(:invoice_batch).permit(:notes, :start_date, :end_date, appointment_ids: [])

    # @TODO: Add validation logic here
    if true
      invoice_batch = CreateInvoiceBatchService.new.call(
        business: current_business,
        params: create_batch_params,
        author: current_user
      )

      render json: {
        message: 'Invoice batch has been created successfully.',
        invoice_batch: invoice_batch
      }
    else
      render json: {
        message: 'Failed to create invoice batch.',
        errors: @invoice_batch.errors.full_messages
      },
      status: 422
    end
  end

  # Return created invoices for the batch
  def invoices
  end

  # FIlter and search for appointments that are not invoiced
  def uninvoiced_appointments_search
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    page = (params[:page] || 1).to_i

    # Use the same logic as the existing uninvoiced reports
    options = Report::Appointments::Uninvoiced::Options.new
    options.start_date = start_date
    options.end_date = end_date
    options.page = page

    report = Report::Appointments::Uninvoiced.make(current_business, options)
    appointments = report.results[:paginated_appointments]

    render json: {
      appointments: appointments.map do |appointment|
        {
          id: appointment.id,
          start_time: appointment.start_time,
          patient_name: appointment.patient.full_name,
          practitioner_name: appointment.practitioner.full_name,
          appointment_type: appointment.appointment_type.name
        }
      end,
      pagination: {
        current_page: appointments.current_page,
        total_pages: appointments.total_pages,
        total_count: appointments.total_count
      }
    }
  rescue Date::Error
    render json: { error: 'Invalid date format' }, status: :unprocessable_entity
  end

  def send_email
    # Implementation for sending batch emails
  end

  def destroy
    @invoice_batch.destroy
    redirect_to invoice_batches_path, notice: 'Invoice batch was successfully deleted.'
  end

  private

  def set_invoice_batch
    @invoice_batch = current_business.invoice_batches.find(params[:id])
  end
end