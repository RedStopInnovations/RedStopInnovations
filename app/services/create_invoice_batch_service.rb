class CreateInvoiceBatchService
  def call(business:, params:, author:)
    @business = business
    @params = params
    @author = author

    InvoiceBatch.transaction do
      @invoice_batch = InvoiceBatch.new(
        business: @business,
        author: @author,
        notes: @params[:notes],
        start_date: @params[:start_date],
        end_date: @params[:end_date],
        status: InvoiceBatch::STATUS_PENDING,
        options: @params[:options] || {}
      )

      appointment_ids = @params[:appointment_ids].uniq || []
      @invoice_batch.appointments_count = appointment_ids.size
      appointment_ids.each do |appointment_id|
        @invoice_batch.invoice_batch_items.new(
          appointment_id: appointment_id,
          status: InvoiceBatchItem::STATUS_PENDING
        )
      end

      @invoice_batch.save!
    end

    if @invoice_batch && @invoice_batch.persisted?
      ProcessInvoiceBatchJob.perform_later(@invoice_batch.id)
    end

    @invoice_batch
  end
end