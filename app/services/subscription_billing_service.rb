class SubscriptionBillingService
  # Create invoice for current billing circle
  def create_subscription_invoice(subscription)
    now = Time.current
    billing_items_query =
      subscription.
      subscription_billings.
      where(
        first_invoice_date: subscription.billing_start..subscription.billing_end,
        business_invoice_id: nil
      )
    invoice = nil

    ActiveRecord::Base.transaction do
      invoice = BusinessInvoice.new(
        issue_date: now,
        discount: 0,
        payment_status: "pending"
      )

      invoice_items = build_invoice_items(billing_items_query.to_a)

      if invoice_items.present?
        invoice.items_attributes = invoice_items
        invoice.assign_attributes(
          business_id: subscription.business_id,
          billing_start_date: subscription.billing_start,
          billing_end_date: subscription.billing_end
        )
        invoice.save!

        billing_items_query.update_all(business_invoice_id: invoice.id)
      end
    end

    if invoice.persisted?
      return invoice
    end
  end

  def bill_appointment(business, appointment_id, trigger_type)
    return if business.in_trial_period?
    return if business.subscription_appointment_price == 0

    appointment = Appointment.unscoped.find appointment_id

    now = Time.current

    billed_item = SubscriptionBilling.find_or_initialize_by(
      appointment_id: appointment.id,
      billing_type: 'APPOINTMENT'
    )
    if billed_item.persisted?
      unless billed_item.triggers.include?(trigger_type)
        billed_item.triggers << trigger_type
      end
    else
      billed_item.assign_attributes(
        first_invoice_date: now,
        subscription_id: business.subscription.id,
        subscription_price_on_date: business.subscription_appointment_price,
        quantity: 1,
        trigger_type: trigger_type,
        triggers: [trigger_type]
      )
    end

    billed_item.save!

    billed_item
  end

  def create_sms_billing_item(business, description = nil, related_appointment = nil)
    price = business.subscription_sms_price

    appointment_id = related_appointment.try(:id)

    SubscriptionBilling.create!(
      appointment_id: appointment_id,
      first_invoice_date: Time.current,
      subscription_id: business.subscription.id,
      subscription_price_on_date: price,
      billing_type: 'SMS',
      quantity: 1,
      description: description
    )
  end

  def renew_billing_cycle(subscription)
    subscription.billing_start = subscription.billing_end + 1.day
    subscription.billing_end = subscription.billing_start + 30.days
    subscription.save!
  end

  # Build invoice items by group by type and price
  # If invoice total not zero and less than the minimum subscription fee,
  # only charge single item name "Minimum subscription fee" for $15
  def build_invoice_items(billing_items)
    if billing_items.empty?
      return []
    else
      invoice_items = []

      billing_items.group_by do |item|
        {
          billing_type: item.billing_type,
          price: item.subscription_price_on_date,
        }
      end.each do |group, items|
        total_quantity = items.sum(&:quantity)
        invoice_item_amount = group[:price] * total_quantity

        invoice_items << {
          unit_name: group[:billing_type],
          unit_price: group[:price],
          quantity: total_quantity,
          amount: invoice_item_amount
        }
      end

      subtotal = invoice_items.sum { |item| item[:amount] }

      if subtotal < App::MINIMUM_SUBSCRIPTION_FEE
        return [{
          unit_name: 'MINIMUM SUBSCRIPTION FEE',
          unit_price: App::MINIMUM_SUBSCRIPTION_FEE,
          quantity: 1,
          amount: App::MINIMUM_SUBSCRIPTION_FEE * 1
        }]
      else
        return invoice_items
      end
    end
  end

  private

  def create_invoice(subscription)
    now = Time.current
    business_invoice = BusinessInvoice.create!(
      business_id: subscription.business_id,
      issue_date: now,
      discount: 0,
      payment_status: "pending"
    )

    business_invoice
  end
end
