module SearchAppointment
  class Filters
    include Virtus.model
    include ActiveModel::Model

    attribute :business_id, Integer
    attribute :patient_id, Integer
    attribute :start_date, String
    attribute :end_date, String
    attribute :location, String
    attribute :distance, Integer, default: 20
    attribute :availability_type_id, Integer
    attribute :practitioner_group_id, Integer
    attribute :practitioner_id, Integer
    attribute :profession, String
    attribute :page, Integer, default: 1
    attribute :per_page, Integer, default: 10
  end
end
