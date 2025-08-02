class ProcessInvoiceBatchJob < ApplicationJob
  def perform(invoice_batch_id)
    invoice_batch = InvoiceBatch.find(invoice_batch_id)
    @business = invoice_batch.business

    return unless [InvoiceBatch::STATUS_PENDING, InvoiceBatch::STATUS_IN_PROGRESS, InvoiceBatch::STATUS_ERROR].include?(invoice_batch.status) # Skip if the batch is not pending

    begin
      invoice_batch.update(status: InvoiceBatch::STATUS_IN_PROGRESS)

      invoice_batch.invoice_batch_items.includes(:appointment, :invoice).each do |invoice_batch_item|
        if invoice_batch_item.status != InvoiceBatchItem::STATUS_CREATED
          InvoiceBatchItem.transaction do
            begin
              appointment = invoice_batch_item.appointment
              patient = appointment.patient
              appointment_type = appointment.appointment_type
              default_billable_items = appointment_type.billable_items
              existing_invoice = invoice_batch_item.invoice || @business.invoices.exists?(appointment_id: appointment.id)

              skip = false
              skip_reason = nil

              if !appointment || appointment.deleted_at?  # Skip if appointment is not present or deleted
                skip = true
                skip_reason = "Appointment deleted"
              end

              if !skip && default_billable_items.empty? # Skip if no default billable items found for the appointment type
                skip = true
                skip_reason = "No default billable items"
              end

              if !skip && existing_invoice  # Skip if invoice already exists
                skip = true
                skip_reason = "Invoice already created"
              end

              if skip
                invoice_batch_item.status = InvoiceBatchItem::STATUS_SKIPPED
                invoice_batch_item.notes = skip_reason
              else
                invoice_to_contact = patient.invoice_to_contacts.first

                invoice = Invoice.new(
                  business: @business,
                  patient: patient,
                  issue_date: Date.current,
                  service_date: appointment.start_time_in_practitioner_timezone.to_date,
                  invoice_number: generate_invoice_number,
                  practitioner_id: appointment.practitioner.id,
                  provider_number: appointment.practitioner.medicare.presence,
                  appointment: appointment,
                  patient_case_id: appointment.patient_case_id,
                  invoice_to_contact_id: invoice_to_contact&.id,
                )

                invoice.assign_attributes generate_invoice_amount_and_items_attributes(default_billable_items)

                invoice.save!(validate: false)
                invoice_batch_item.assign_attributes(
                  invoice_id: invoice.id,
                  status: InvoiceBatchItem::STATUS_CREATED,
                  notes: nil
                )
              end

              invoice_batch_item.save!
            rescue => e
              Rails.logger.error("Error processing invoice batch item #{invoice_batch_item.id}: #{e.message}")
              invoice_batch_item.status = InvoiceBatchItem::STATUS_ERROR
              invoice_batch_item.notes = "Internal error."
              invoice_batch_item.save!
              raise e if Rails.env.development?
            end
          end
        end
      end
      # Update the invoice batch status and counts
      invoice_batch.status = InvoiceBatch::STATUS_COMPLETE
      invoice_batch.invoices_count = invoice_batch.invoice_batch_items.where(status: InvoiceBatchItem::STATUS_CREATED).count
      invoice_batch.total_invoices_amount = invoice_batch.invoices.sum(:amount)
      invoice_batch.save!
    rescue => e
      Rails.logger.error("Error processing invoice batch #{invoice_batch.id}: #{e.message}")
      invoice_batch.status = InvoiceBatch::STATUS_ERROR
      invoice_batch.save!
      raise e if Rails.env.development?
    end
  end

  private

  def generate_invoice_amount_and_items_attributes(default_billable_items)
    invoice_attrs = {
      items_attributes: [],
    }
    total_amount = 0
    total_amount_ex_tax = 0

    default_billable_items.each do |billable_item|
      invoice_item_attrs = {
        invoiceable_id: billable_item.id,
        invoiceable_type: billable_item.class.name,
        quantity: 1, # Default quantity is 1 for each billable item
        unit_price: billable_item.price,
        unit_name: billable_item.name,
        tax_name: billable_item.tax_name,
        tax_rate: billable_item.tax_rate,
        item_number: billable_item.item_number
      }

      item_amount_ex_tax = 1 * billable_item.price

      item_tax_amount =
        if billable_item.tax_rate
          billable_item.tax_rate * item_amount_ex_tax / 100
        else
          0
        end

      item_total_amount = item_amount_ex_tax + item_tax_amount
      total_amount_ex_tax += item_amount_ex_tax
      total_amount += item_total_amount

      invoice_attrs[:items_attributes] << invoice_item_attrs
    end

    invoice_attrs.merge!(
      amount: total_amount,
      amount_ex_tax: total_amount_ex_tax,
      outstanding: total_amount
    )

    invoice_attrs
  end

  def generate_invoice_number
    max_number = @business.invoices.with_deleted.maximum "CAST(invoice_number AS integer)"
    max_number = 0 if max_number.nil?

    invoice_start_number = @business.invoice_setting.try(:starting_invoice_number)
    invoice_start_number = 1 if invoice_start_number.nil?

    number =
      if invoice_start_number > max_number
        invoice_start_number
      else
        max_number + 1
      end

    # Invoice numbers has at least 5 characters with leading zeros
    number.to_s.rjust 5, '0'
  end
end