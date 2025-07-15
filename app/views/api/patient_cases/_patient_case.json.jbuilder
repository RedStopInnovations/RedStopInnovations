json.extract! patient_case, :id, :status, :notes, :invoice_number, :invoice_total, :created_at, :archived_at, :updated_at

json.issued_invoices_amount patient_case.invoices.sum(&:amount).to_f
json.issued_invoices_count patient_case.invoices.count

json.case_type do
  json.extract! patient_case.case_type, :id, :title, :description
end

json.practitioner do
  if patient_case.practitioner
    json.extract! patient_case.practitioner, :id, :full_name, :profession
  end
end