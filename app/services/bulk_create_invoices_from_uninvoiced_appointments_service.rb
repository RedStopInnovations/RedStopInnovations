class BulkCreateInvoicesFromUninvoicedAppointmentsService
  attr_reader :business, :form_request, :author

  # @param business ::Business business
  # @param form_request BulkCreateInvoicesFromUninvoicedAppointmentsForm
  # @param author ::User
  def call(business, form_request, author)
    @business = business
    @form_request = form_request
    @author = author

    appointment_ids = form_request.invoices.map(&:appointment_id)
    appointments = business.appointments.where(id: appointment_ids).to_a

    created_invoices = []

    Invoice.transaction do
      appointments.each do |appt|
        invoice = create_invoice_for_appointment(appt)
        if invoice
          created_invoices << invoice
        end
      end
    end

    created_invoices.each do |invoice|
      after_created_invoice(invoice)
    end

    created_invoices
  end

  private

  def is_send_invoice_after_create_for_appointment?(appointment)
    form_request.invoices.find do |invoice|
      invoice.appointment_id == appointment.id
    end.try(:send_after_create)
  end

  def find_patient_case_id_for_appointment(appointment)
    form_request.invoices.find do |invoice|
      invoice.appointment_id == appointment.id
    end.try(:patient_case_id)
  end

  def create_invoice_for_appointment(appointment)
    patient = appointment.patient
    default_billable_items = appointment.appointment_type.billable_items

    if default_billable_items.size == 0
      return nil
    end

    if Invoice.where(appointment_id: appointment.id).exists?
      return nil
    end

    invoice = Invoice.new(
      patient_id: appointment.patient.id,
      issue_date: Date.current,
      business_id: business.id,
      appointment_id: appointment.id,
      invoice_number: generate_invoice_number,
      service_date: appointment.start_time_in_practitioner_timezone.to_date,
      practitioner_id: appointment.practitioner.id,
      provider_number: appointment.practitioner.medicare.presence
    )

    invoice_to_contact = patient.primary_invoice_to_contact

    if invoice_to_contact
      invoice.invoice_to_contact_id = invoice_to_contact.id
    end

    default_billable_items.each do |billable_item|
      unit_price = billable_item.price

       # Check to apply variable pricing
      if invoice_to_contact
        pricing_for_this_contact = billable_item.pricing_contacts.where(contact_id: invoice_to_contact.id).first
        if pricing_for_this_contact
          unit_price = pricing_for_this_contact.price
        end
      end

      invoice.items.new(
        invoiceable: billable_item,
        quantity: 1,
        unit_price: unit_price,
        unit_name: billable_item.name,
        tax_name: billable_item.tax_name,
        tax_rate: billable_item.tax_rate,
        item_number: billable_item.item_number
      )
    end

    invoice.assign_attributes calculate_invoice_amount_attributes(invoice)
    invoice.patient_case_id = find_patient_case_id_for_appointment(appointment)

    invoice.save!(validate: false)

    invoice
  end

  def after_created_invoice(invoice)
    patient = invoice.patient
    appointment = invoice.appointment

    # Send email
    if is_send_invoice_after_create_for_appointment?(appointment)
      SendInvoiceService.new.call(invoice, author)
    end

    ::Webhook::Worker.perform_later(invoice.id, WebhookSubscription::INVOICE_CREATED)

    # Send practitioner review request
    if business.communication_template_enabled?(CommunicationTemplate::TEMPLATE_ID_SATISFACTION_REVIEW_REQUEST) &&
      patient.email? && patient.reminder_enable? &&
      !Review.where(practitioner_id: appointment.practitioner_id, patient_id: patient.id).exists?
      ReviewMailer.review_request_mail(appointment).deliver_later
    end

    schedule_outstanding_reminder(invoice)
  end

  def calculate_invoice_amount_attributes(invoice)
    total_amount = 0
    total_amount_ex_tax = 0

    invoice.items.each do |ii|
      invoiceable = ii.invoiceable
      item_amount_ex_tax = ii.quantity * ii.unit_price
      item_tax_amount =
        if invoiceable.tax_rate
          invoiceable.tax_rate * item_amount_ex_tax / 100
        else
          0
        end

      item_total_amount = item_amount_ex_tax + item_tax_amount
      total_amount_ex_tax += item_amount_ex_tax
      total_amount += item_total_amount
    end

    {
      amount: total_amount,
      amount_ex_tax: total_amount_ex_tax,
      outstanding: total_amount
    }
  end

  def schedule_outstanding_reminder(invoice)
    outstanding_reminder_com_template = business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER)

    if outstanding_reminder_com_template && outstanding_reminder_com_template.enabled?
      reminder_settings = outstanding_reminder_com_template.settings || {}

      if reminder_settings['outstanding_days'].present?
        first_reminder_at = invoice.created_at + reminder_settings['outstanding_days'].days
        job_jid = OutstandingInvoiceReminderWorker.perform_at(first_reminder_at, invoice.id)

        invoice_outstanding_reminder_info = {
          enable: true,
          reminders_count: 0,
          scheduled_job_id: job_jid,
          scheduled_job_perform_at: first_reminder_at.to_i
        }

        invoice.update_column :outstanding_reminder, invoice_outstanding_reminder_info
      end
    end
  end

  def generate_invoice_number
    max_number = business.invoices.with_deleted.maximum "CAST(invoice_number AS integer)"
    max_number = 0 if max_number.nil?

    invoice_start_number = business.invoice_setting.try(:starting_invoice_number)
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