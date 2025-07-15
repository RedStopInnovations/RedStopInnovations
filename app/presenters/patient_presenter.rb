class PatientPresenter < BasePresenter
  def invoice_to
    result = []

    self.invoice_to_contacts.each do |contact|
      result << {
        id: contact.id,
        name: contact.business_name,
        business_name: contact.business_name,
        first_name: contact.first_name,
        last_name: contact.last_name,
        full_name: contact.full_name.presence,
      }
    end
    result
  end

  def cases
    result = []
    business = self.business
    self.patient_cases.each do |patient_case|
      extra_info = ""
      if patient_case.invoice_number?
        extra_info << "Invoiced: #{patient_case.invoices.count}/#{patient_case.invoice_number}"
      else
        extra_info << "Invoiced: #{patient_case.invoices.count}"
      end

      if patient_case.invoice_total?
        extra_info << " $#{patient_case.invoices.sum(&:amount)}/$#{patient_case.invoice_total}"
      else
        extra_info << " $#{patient_case.invoices.sum(&:amount)}"
      end

      result << {
        id: patient_case.id,
        name: "#{patient_case.case_type.try(:title)} - #{patient_case.status} - #{extra_info}"
      }
    end
    result
  end

  def pricing_contacts
    result = []
    self.invoice_to_contacts.includes(:pricing_billable_items).each do |contact|
      contact_date = { id: contact.id, billable_items: {}}
      contact.pricing_billable_items.each do |item|
        contact_date[:billable_items][item.billable_item_id] = { id: item.billable_item_id, price: item.price}
      end
      result << contact_date if contact.pricing_billable_items.present?
    end
    result
  end

  %i(medicare_referral_date dva_referral_date ndis_plan_start_date ndis_plan_end_date hih_discharge_date hih_surgery_date)
  .each do |date_attr|

    define_method :"display_#{date_attr}" do
      if self.send(date_attr).present?
        self.send(date_attr).to_date.strftime(I18n.t('date.common'))
      else
        nil
      end

      rescue Date::Error
        nil
    end
  end
end
