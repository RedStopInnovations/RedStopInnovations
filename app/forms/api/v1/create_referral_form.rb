module Api
  module V1
    class CreateReferralForm < BaseForm
      attr_accessor :business

      class PatientInfo < BaseForm
        attribute :referral_type, String
        attribute :first_name, String
        attribute :last_name, String
        attribute :dob, String
        attribute :phone, String
        attribute :mobile, String
        attribute :email, String
        attribute :address1, String
        attribute :city, String
        attribute :state, String
        attribute :postcode, String
        attribute :country, String
        attribute :aboriginal_status, String
        attribute :next_of_kin, String
        attribute :general_info, String

        validates_presence_of :first_name,
                              :last_name,
                              :dob

        validates :address1, :city, :state, :postcode, :country,
                  length: { maximum: 50 },
                  allow_blank: true,
                  allow_nil: true

        validates_length_of :first_name, :last_name,
                            minimum: 1,
                            maximum: 25,
                            allow_blank: true,
                            allow_nil: true

        validates_date :dob, allow_nil: true, allow_blank: true, message: 'is not valid. Date format is dd/mm/yyyy.'
        validates :email, email: :true, allow_blank: true, allow_nil: true

        validates :phone,
                  length: { maximum: 20 },
                  allow_nil: true,
                  allow_blank: true

        validates :mobile,
                  length: { maximum: 20 },
                  allow_nil: true,
                  allow_blank: true

        validates :next_of_kin,
                  length: { maximum: 500 },
                  allow_nil: true,
                  allow_blank: true

        validates :general_info,
                  length: { maximum: 5000 },
                  allow_nil: true,
                  allow_blank: true

        attribute :medicare_card_number, String
        attribute :medicare_card_irn, String
        attribute :medicare_referrer_name, String
        attribute :medicare_referrer_provider_number, String
        attribute :medicare_referral_date, String

        # DVA details
        attribute :dva_file_number, String
        attribute :dva_card_type, String
        attribute :dva_referrer_name, String
        attribute :dva_referrer_provider_number, String
        attribute :dva_referral_date, String

        # NDIS details
        attribute :ndis_client_number, String
        attribute :ndis_plan_start_date, String
        attribute :ndis_plan_end_date, String
        attribute :ndis_plan_manager_name, String
        attribute :ndis_plan_manager_phone, String
        attribute :ndis_plan_manager_email, String

        # Home care package details
        attribute :hcp_company_name, String
        attribute :hcp_manager_name, String
        attribute :hcp_manager_phone, String
        attribute :hcp_manager_email, String

        # Hospital in the home details
        attribute :hih_hospital, String
        attribute :hih_procedure, String
        attribute :hih_discharge_date, String
        attribute :hih_surgery_date, String
        attribute :hih_doctor_name, String
        attribute :hih_doctor_phone, String
        attribute :hih_doctor_email, String

        # Health insurance details
        attribute :hi_company_name, String
        attribute :hi_number, String
        attribute :hi_manager_name, String
        attribute :hi_manager_email, String
        attribute :hi_manager_phone, String

        # STRC details
        attribute :strc_company_name, String
        attribute :strc_company_phone, String
        attribute :strc_invoice_to_name, String
        attribute :strc_invoice_to_email, String

        validates_presence_of :hcp_company_name,
                  :hcp_manager_name,
                  :hcp_manager_phone,
                  :hcp_manager_email,
                  if: Proc.new { |p| p.referral_type == Referral::TYPE_HCP }

        validates_presence_of :medicare_card_number,
                  :medicare_card_irn,
                  :medicare_referrer_name,
                  :medicare_referrer_provider_number,
                  :medicare_referral_date,
                  presence: true,
                  if: Proc.new { |p| p.referral_type == Referral::TYPE_MEDICARE }

        validates_presence_of :dva_file_number,
                  :dva_card_type, # Gold card, White card
                  :dva_referrer_name,
                  :dva_referrer_provider_number,
                  :dva_referral_date,
                  presence: true,
                  if: Proc.new { |p| p.referral_type == Referral::TYPE_DVA }

        validates :dva_card_type,
                  inclusion: { in: ['Gold card', 'White card'] },
                  allow_nil: true,
                  allow_blank: true

        validates_presence_of :ndis_client_number,
                  :ndis_plan_start_date,
                  :ndis_plan_end_date,
                  presence: true,
                  if: Proc.new { |p| p.referral_type == Referral::TYPE_NDIS }

        validates_presence_of :strc_company_name,
                  :strc_company_phone,
                  :strc_invoice_to_name,
                  :strc_invoice_to_email,
                  presence: true,
                  if: Proc.new { |p| p.referral_type == Referral::TYPE_STRC }

        validates :medicare_card_number,
                  :medicare_card_irn,
                  :medicare_referrer_provider_number,
                  :dva_referrer_provider_number,
                  :ndis_client_number,
                  :hi_number,
                  :dva_file_number,
                  length: { maximum: 50 },
                  allow_nil: true,
                  allow_blank: true

        validates :medicare_referrer_name,
                  :dva_referrer_name,
                  :ndis_plan_manager_name,
                  :hcp_manager_name,
                  :hih_doctor_name,
                  :hi_manager_name,
                  :strc_invoice_to_name,
                  length: { maximum: 50 },
                  allow_nil: true,
                  allow_blank: true

        validates :hih_hospital,
                  :hcp_company_name,
                  :hi_company_name,
                  :strc_company_name,
                  length: { maximum: 100 },
                  allow_nil: true,
                  allow_blank: true

        validates :hih_procedure,
                  length: { maximum: 300 },
                  allow_nil: true,
                  allow_blank: true

        validates :ndis_plan_manager_email,
                  :hcp_manager_email,
                  :hi_manager_email,
                  :strc_invoice_to_email,
                  email: true,
                  length: { maximum: 255 },
                  allow_nil: true,
                  allow_blank: true

        validates :ndis_plan_manager_phone,
                  :hcp_manager_phone,
                  :hih_doctor_phone,
                  :hi_manager_phone,
                  :strc_company_phone,
                  length: { maximum: 50 },
                  allow_nil: true,
                  allow_blank: true

        # Dates
        validates_date :medicare_referral_date,
                  :dva_referral_date,
                  :ndis_plan_start_date,
                  :ndis_plan_end_date,
                  allow_nil: true,
                  allow_blank: true

      end

      attribute :patient, PatientInfo, default: lambda { |referral, attribute|
        PatientInfo.new(referral_type: referral.referral_type)
      }

      attribute :referral_type, String
      attribute :priority, String

      attribute :availability_type, String
      attribute :practitioner_id, Integer
      attribute :professions, Array[String]

      attribute :referrer_business_name, String
      attribute :referrer_name, String
      attribute :referrer_phone, String
      attribute :referrer_email, String

      attribute :referral_reason, String

      attribute :medical_note, String

      validates :referral_type,
                inclusion: { in: Referral::TYPES },
                allow_nil: true,
                allow_blank: true

      validates :referrer_business_name,
                presence: true,
                length: { maximum: 100 },
                allow_nil: true,
                allow_blank: true

      validates :referrer_name,
                presence: true,
                length: { maximum: 50 },
                allow_nil: true,
                allow_blank: true

      validates :referrer_phone,
                presence: true,
                length: { maximum: 50 },
                allow_nil: true,
                allow_blank: true

      validates :referrer_email,
                presence: true,
                email: true,
                length: { maximum: 255 },
                allow_nil: true,
                allow_blank: true

      validates :professions,
                presence: true

      validates :availability_type,
                  presence: true,
                  inclusion: {
                    in: ['HOME_VISIT', 'FACILITY'],
                    message: 'is not valid. Allowed values are HOME_VISIT, FACILITY'
                  }

      validates :medical_note,
                length: { maximum: 5000 },
                allow_nil: true,
                allow_blank: true

      validates :priority,
                inclusion: {
                  in: ['Urgent', 'Normal'],
                  message: 'is not valid. Allowed values are Normal, Urgent'
                },
                allow_nil: true,
                allow_blank: true

      validates :referral_reason,
                length: { maximum: 5000 },
                allow_nil: true,
                allow_blank: true

      validate do
        patient.validate

        unless patient.valid?
          errors.add(:patient, 'Patient info is invalid')

          errors.merge! patient.errors
        end

        if practitioner_id.present? && !business.practitioners.exists?(id: practitioner_id)
          errors.add(:practitioner_id, 'is invalid')
        end

        if professions.present? && !(professions - ::Practitioner::PROFESSIONS).empty?
          errors.add(:professions, 'is invalid')
        end
      end
    end
  end
end
