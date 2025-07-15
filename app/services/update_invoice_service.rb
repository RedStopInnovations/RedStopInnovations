class UpdateInvoiceService
  def call(invoice, validated_update_params)
    @invoice = invoice
    @business = @invoice.business
    patient = @invoice.patient

    # @TODO: move following checks to a form class
    if validated_update_params[:appointment_id].present?
      raise ArgumentError.new('Invalid appointment') unless patient.appointments.exists?(id: validated_update_params[:appointment_id])
    end

    if validated_update_params[:patient_case_id].present?
      raise ArgumentError.new('Invalid client case') unless patient.patient_cases.exists?(id: validated_update_params[:patient_case_id])
    end

    if validated_update_params[:invoice_to_contact_id].present?
      raise ArgumentError.new('Invalid contact') unless @business.contacts.exists?(id: validated_update_params[:invoice_to_contact_id])
    end

    if validated_update_params[:task_id].present?
      raise ArgumentError.new('Invalid task') unless patient.tasks.exists?(id: validated_update_params[:task_id])
    end

    @invoice.assign_attributes validated_update_params
    @invoice.assign_attributes calculate_amount_attributes

    if @invoice.appointment_id_changed? && @invoice.appointment.present?
      appt = @invoice.appointment
      @invoice.service_date = appt.start_time_in_practitioner_timezone.to_date
      @invoice.practitioner_id = appt.practitioner_id
      @invoice.provider_number = appt.practitioner.medicare.presence
    elsif @invoice.task_id_changed? && @invoice.task.present?
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

    @invoice.save!(validate: false)

    @invoice
  end

  private

  def calculate_amount_attributes
    total_amount = 0
    total_amount_ex_tax = 0

    @invoice.items.each do |ii|
      next if ii.marked_for_destruction?

      item_amount_ex_tax = ii.quantity * ii.unit_price
      tax_rate = nil

      # If the invoice item is persisted, get the tax rate from the "tax_rate" column
      if ii.persisted?
        tax_rate = ii.tax_rate
      else
        # If the invoice item is new, get the tax rate from the invoiceable object
        invoiceable = ii.invoiceable
        tax_rate = invoiceable.tax_rate

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
      end

      if tax_rate && tax_rate > 0
        item_tax_amount = tax_rate * item_amount_ex_tax / 100
      else
        item_tax_amount = 0
      end

      item_total_amount = item_amount_ex_tax + item_tax_amount
      total_amount_ex_tax += item_amount_ex_tax
      total_amount += item_total_amount
    end

    paid_amount = @invoice.payment_allocations.sum(:amount)

    outstanding_amount =
      if paid_amount > total_amount
        0
      else
        total_amount - paid_amount
      end

    {
      amount: total_amount,
      amount_ex_tax: total_amount_ex_tax,
      outstanding: outstanding_amount
    }
  end
end