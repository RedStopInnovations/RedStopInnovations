class UpdatePatientForm < BaseForm
  attribute :first_name, String
  attribute :last_name, String
  attribute :dob, String

  attribute :gender, String
  attribute :next_of_kin, String
  attribute :nationality, String
  attribute :spoken_languages, String
  attribute :aboriginal_status, String

  attribute :email, String
  attribute :phone, String
  attribute :mobile, String

  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String

  attribute :general_info, String
  attribute :reminder_enable, Boolean, default: true
  attribute :accepted_privacy_policy, Boolean

  attribute :referrer_contact_ids, Array[Integer]
  attribute :invoice_to_contact_ids, Array[Integer]
  attribute :doctor_contact_ids, Array[Integer]
  attribute :specialist_contact_ids, Array[Integer]
  attribute :other_contact_ids, Array[Integer]

  validates_presence_of :first_name,
                        :last_name,
                        :dob

  validates :address1, :city, :state, :postcode, :country,
            presence: true,
            length: { maximum: 50 }

  validates_length_of :first_name, :last_name,
                       minimum: 1,
                       maximum: 25,
                       allow_blank: true,
                       allow_nil: true

  validates_date :dob,
                 before: :today,
                 format: 'yyyy-mm-dd',
                 before_message: 'must be in the past',
                 message: 'is not valid. Valid format is dd/mm/yyyy.'

  validates :general_info,
            length: { maximum: 10000 },
            allow_nil: true,
            allow_blank: true

  validates :email, email: :true, allow_blank: true, allow_nil: true

  validates_length_of :phone, :mobile, maximum: 50

  validates_length_of :next_of_kin, :general_info, maximum: 10000

  def self.hydrate(patient)
    attrs = patient.attributes.symbolize_keys.slice(
      :first_name,
      :last_name,
      :phone,
      :mobile,
      :email,
      :address1,
      :address2,
      :city,
      :state,
      :postcode,
      :country,
      :dob,
      :gender,
      :reminder_enable,
      :general_info,
      :next_of_kin,
      :nationality,
      :aboriginal_status,
      :spoken_languages,
      :accepted_privacy_policy
    )

    patient.preload_tagged_contacts

    attrs[:referrer_contact_ids] = patient.referrer_contact_ids
    attrs[:invoice_to_contact_ids] = patient.invoice_to_contact_ids
    attrs[:doctor_contact_ids] = patient.doctor_contact_ids
    attrs[:specialist_contact_ids] = patient.specialist_contact_ids
    attrs[:other_contact_ids] = patient.other_contact_ids

    new(attrs)
  end
end
