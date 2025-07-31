json.extract! patient_case, :id, :case_number, :status, :notes, :invoice_number, :invoice_total, :created_at, :archived_at, :updated_at

json.issued_invoices_amount patient_case.invoices.sum(&:amount).to_f
json.appointments_count patient_case.appointments.not_cancelled.count

json.case_type do
  if patient_case.case_type
    json.extract! patient_case.case_type, :id, :title, :description
  end
end

json.practitioner do
  if patient_case.practitioner
    json.extract! patient_case.practitioner, :id, :full_name, :profession
  end
end