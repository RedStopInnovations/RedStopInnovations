class CreatePatientForm < BaseForm
  attribute :title, String
  attribute :first_name, String
  attribute :last_name, String
  attribute :dob, String

  attribute :gender, String
  attribute :next_of_kin, String
  attribute :nationality, String
  attribute :spoken_languages, String
  attribute :aboriginal_status, String
  attribute :extra_invoice_info, String

  attribute :tag_ids, Array[Integer]

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

  validates_presence_of :first_name,
                        :last_name,
                        :dob

  validates :address1, :city, :state, :postcode, :country,
            presence: true,
            length: { maximum: 50 }

  validates_length_of :title,
                       minimum: 2,
                       maximum: 10,
                       allow_blank: true,
                       allow_nil: true

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
end
