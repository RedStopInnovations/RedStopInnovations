module WaitListSearch
  class Filter
    include Virtus.model

    attribute :patient_search, String
    attribute :location_search, String
    attribute :profession, String
    attribute :appointment_type_id, Integer
    attribute :practitioner_id, Integer
    attribute :start_date, Date
    attribute :end_date, Date
  end
end
