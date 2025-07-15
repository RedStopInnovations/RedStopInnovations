json.extract! invoice,
             :id,
             :invoice_number,
             :issue_date,
             :service_date,
             :amount,
             :amount_ex_tax,
             :outstanding,
             :appointment_id,
             :patient_id,
             :patient_case_id,
             :invoice_to_contact_id,
             :practitioner_id,
             :task_id,
             :last_send_at,
             :notes,
             :message,
             :created_at,
             :updated_at

json.items do
  json.array! invoice.items, :id, :unit_name, :quantity, :unit_price, :tax_name, :tax_rate, :amount, :invoiceable, :invoiceable_type, :invoiceable_id
end