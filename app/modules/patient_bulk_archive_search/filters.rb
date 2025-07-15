module PatientBulkArchiveSearch
  class Filters
    include Virtus.model

    attribute :create_date_from, String
    attribute :create_date_to, String
    attribute :contact_id, Integer
    attribute :no_appointment_period, String
    attribute :no_invoice_period, String
    attribute :no_treatment_note_period, String
    attribute :page, Integer, default: 1
    attribute :per_page, Integer, default: 25
  end
end