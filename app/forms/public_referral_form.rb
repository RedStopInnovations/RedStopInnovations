class PublicReferralForm < BaseForm
  class PatientInfo < BaseForm
    attribute :first_name, String
    attribute :last_name, String
    attribute :dob, String
    attribute :phone, String
    attribute :email, String
    attribute :address1, String
    attribute :city, String
    attribute :state, String
    attribute :postcode, String
    attribute :country, String

    validates_presence_of :first_name,
                          :last_name,
                          :dob

    validates_length_of :first_name, :last_name,
                         minimum: 1,
                         maximum: 25,
                         allow_blank: true,
                         allow_nil: true

    validates :address1,
              presence: true,
              length: { maximum: 100 }

    validates :city,
              :state,
              :postcode,
              :country,
              presence: true,
              length: { maximum: 50 }

    validates_date :dob,
                 before: :today,
                 format: 'yyyy-mm-dd',
                 before_message: 'must be in the past',
                 message: 'is not valid. Valid format is dd/mm/yyyy.'

    validates :email, email: :true, allow_blank: true, allow_nil: true

    validates :phone,
              length: { maximum: 50 },
              allow_blank: true,
              allow_nil: true
  end

  attribute :patient, PatientInfo, default: lambda { |referral, attribute|
    PatientInfo.new
  }

  attribute :availability_type_id, Integer
  attribute :profession, String
  attribute :practitioner_id, Integer

  attribute :referrer_business_name, String
  attribute :referrer_name, String
  attribute :referrer_phone, String
  attribute :referrer_email, String

  attribute :medical_note, String
  attribute :attachments, Array[ActionDispatch::Http::UploadedFile]

  validates :referrer_business_name,
            presence: true,
            length: { maximum: 100 }

  validates :referrer_name,
            presence: true,
            length: { maximum: 25 }

  validates :referrer_phone,
            presence: true,
            length: { maximum: 25 }

  validates :referrer_email,
            presence: true,
            email: true,
            length: { maximum: 255 }

  validates :profession,
            presence: true,
            inclusion: {
              in: Practitioner::PROFESSIONS
            }

  validates :availability_type_id,
              presence: true,
              inclusion: {
                in: [AvailabilityType::TYPE_HOME_VISIT_ID, AvailabilityType::TYPE_FACILITY_ID],
                message: 'is not a valid availability type'
              }

  validates :medical_note,
            length: { maximum: 5000 },
            allow_nil: true,
            allow_blank: true

  validate do
    patient.validate

    attachments.each do |attm|
      unless attm.present? && attm.is_a?(ActionDispatch::Http::UploadedFile) &&
        (attm.size <= 5.megabytes) &&
        (['application/pdf', 'image/png', 'image/jpeg'].include?(attm.content_type))
        errors.add(:attachments, 'has invalid file')
      end
    end

    unless errors.key?(:base)
      if attachments.size > 3
        errors.add(:attachments, 'can not be more than 3 files')
      end
    end

    unless patient.valid?
      errors.add(:base, 'Client info is invalid')
    end

    if practitioner_id.present? && !Practitioner.exists?(id: practitioner_id)
      errors.add(:practitioner_id, 'is invalid')
    end
  end
end
