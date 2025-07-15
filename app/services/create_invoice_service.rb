class CreateInvoiceService
  def call(business, validated_create_params)
    @business = business
    @invoice = Invoice.new validated_create_params
    patient = @business.patients.find(validated_create_params[:patient_id])

    # @TODO: move following checks to a form class
    if validated_create_params[:appointment_id].present?
      raise ArgumentError.new('Invalid appointment') unless patient.appointments.exists?(id: validated_create_params[:appointment_id])
    end

    if validated_create_params[:patient_case_id].present?
      raise ArgumentError.new('Invalid client case') unless patient.patient_cases.exists?(id: validated_create_params[:patient_case_id])
    end

    if validated_create_params[:invoice_to_contact_id].present?
      raise ArgumentError.new('Invalid contact') unless @business.contacts.exists?(id: validated_create_params[:invoice_to_contact_id])
    end

    if validated_create_params[:task_id].present?
      raise ArgumentError.new('Invalid task') unless patient.tasks.exists?(id: validated_create_params[:task_id])
    end

    @invoice.assign_attributes(
      business_id: @business.id,
      issue_date: Date.current,
      invoice_number: generate_invoice_number
    )

    if @invoice.appointment.present?
      appt = @invoice.appointment
      @invoice.service_date = appt.start_time_in_practitioner_timezone.to_date
      @invoice.practitioner_id = appt.practitioner.id
      @invoice.provider_number = appt.practitioner.medicare.presence
    elsif @invoice.task.present?
      task_assignment = @invoice.task.task_users.first

      if task_assignment
        if task_assignment.complete_at?
          @invoice.service_date = task_assignment.complete_at.to_date
        end

        assignee = task_assignment.user

        if assignee.is_practitioner?
          @invoice.practitioner_id = assignee.practitioner.id
          @invoice.provider_number = assignee.practitioner.medicare.presence
        end
      end
    end

    @invoice.assign_attributes calculate_amount_attributes

    @invoice.save!(validate: false)

    ::Webhook::Worker.perform_later(@invoice.id, WebhookSubscription::INVOICE_CREATED)

    # Automated associate the contact as 'Invoice To' to the patient
    if @invoice.invoice_to_contact_id?
      contact = @business.contacts.find(@invoice.invoice_to_contact_id)
      unless patient.patient_invoice_to_contacts.exists?(contact_id: contact.id)
        PatientContact.create(
          patient_id: patient.id,
          contact_id: contact.id,
          type: PatientContact::TYPE_INVOICE_TO
        )
      end
    end

    # Send practitioner review request
    appointment = @invoice.appointment
    if appointment.present? && patient.email? && patient.reminder_enable? &&
        !Review.where(
            practitioner_id: appointment.practitioner_id, patient_id: patient.id
        ).exists? &&
      @business.communication_template_enabled?('satisfaction_review_request')

      ReviewMailer.review_request_mail(appointment).deliver_later
    end

    # Schedule the outstanding reminder if enabled
    outstanding_reminder_com_template = @business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER)

    if outstanding_reminder_com_template && outstanding_reminder_com_template.enabled?
      reminder_settings = outstanding_reminder_com_template.settings || {}

      if reminder_settings['outstanding_days'].present?
        first_reminder_at = @invoice.created_at + reminder_settings['outstanding_days'].days
        job_jid = OutstandingInvoiceReminderWorker.perform_at(first_reminder_at, @invoice.id)

        invoice_outstanding_reminder_info = {
          enable: true,
          reminders_count: 0,
          scheduled_job_id: job_jid,
          scheduled_job_perform_at: first_reminder_at.to_i
        }

        @invoice.update_column :outstanding_reminder, invoice_outstanding_reminder_info
      end
    end

    @invoice
  end

  private

  def calculate_amount_attributes
    total_amount = 0
    total_amount_ex_tax = 0

    @invoice.items.each do |ii|
      invoiceable = ii.invoiceable
      item_amount_ex_tax = ii.quantity * ii.unit_price

      # Remember the tax as the time the item is created
      ii.unit_name = invoiceable.name
      ii.tax_name = invoiceable.tax_name
      ii.tax_rate = invoiceable.tax_rate
      ii.item_number =
        case invoiceable
        when BillableItem
          invoiceable.item_number
        when Product
          invoiceable.item_code
        end

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