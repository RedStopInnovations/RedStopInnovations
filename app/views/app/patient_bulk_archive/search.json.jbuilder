json.patients do

  json.array! @patients do |patient|
    json.extract! patient, :id,
      :first_name,
      :last_name,
      :full_name,
      :dob,
      :full_address,
      :short_address,
      :address1,
      :address2,
      :city,
      :state,
      :postcode,
      :country,
      :created_at
    # @FIXME: N + 1 query
    json.appointments_count patient.appointments.count
    json.last_appointment_at patient.appointments.order('start_time DESC').first.try(:start_time)

    json.invoices_count patient.invoices.count
    json.last_invoice_issue_date patient.invoices.order('issue_date DESC').first.try(:issue_date)
    json.invoices_outstanding_count patient.invoices.where('outstanding > 0').count

    json.treatment_notes_count patient.treatments.count
    json.last_treatment_note_created_at patient.treatments.order('created_at DESC').first.try(:created_at)
  end
end

json.pagination do
  json.current_page @patients.current_page
  json.total_pages @patients.total_pages
  json.total_entries @patients.total_count
end