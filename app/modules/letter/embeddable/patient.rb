module Letter
  module Embeddable
    class Patient < Base
      VARIABLES = [
        'Patient.FullName',
        'Patient.FirstName',
        'Patient.LastName',
        'Patient.DateOfBirth',
        'Patient.Email',
        'Patient.Mobile',
        'Patient.Phone',
        'Patient.Gender',
        'Patient.FullAddress',
        'Patient.ShortAddress',
        'Patient.Address1',
        'Patient.Address2',
        'Patient.City',
        'Patient.State',
        'Patient.PostCode',
        'Patient.Country',
        'Patient.NextOfKin',
        'Patient.Nationality',
        'Patient.AboriginalStatus',

        # Medicare
        'Patient.Medicare.CardNumber',
        'Patient.Medicare.CardIRN',
        'Patient.Medicare.ReferrerName',
        'Patient.Medicare.ReferrerProviderNumber',
        'Patient.Medicare.ReferralDate',

        # DVA
        'Patient.DVA.FileNumber',
        'Patient.DVA.CardType',
        'Patient.DVA.Hospital',
        'Patient.DVA.WhiteCardDisability',
        'Patient.DVA.ReferrerName',
        'Patient.DVA.ReferrerProviderNumber',
        'Patient.DVA.ReferralDate',

        # NDIS
        'Patient.NDIS.ClientNumber',
        'Patient.NDIS.PlanStartDate',
        'Patient.NDIS.PlanEndDate',
        'Patient.NDIS.PlanManagerName',
        'Patient.NDIS.PlanManagerPhone',
        'Patient.NDIS.PlanManagerEmail',

        # HCP
        'Patient.HCP.CompanyName',
        'Patient.HCP.ManagerName',
        'Patient.HCP.ManagerPhone',
        'Patient.HCP.ManagerEmail',

        # HIH
        'Patient.HIH.Hospital',
        'Patient.HIH.Procedure',
        'Patient.HIH.DischargeDate',
        'Patient.HIH.SurgeryDate',
        'Patient.HIH.DoctorName',
        'Patient.HIH.DoctorPhone',
        'Patient.HIH.DoctorEmail',

        # HI
        'Patient.HI.CompanyName',
        'Patient.HI.Number',
        'Patient.HI.ManagerName',
        'Patient.HI.ManagerEmail',
        'Patient.HI.ManagerPhone',
      ]

      # @param patient ::Patient
      def initialize(patient)
        @patient = patient
        super map_attributes
      end

      private

      def map_attributes
        map = {}

        map['Patient.FullName'] = @patient.full_name
        map['Patient.FirstName'] = @patient.first_name
        map['Patient.LastName'] = @patient.last_name
        map['Patient.DateOfBirth'] = @patient.dob.try(:strftime, I18n.t('date.dob'))
        map['Patient.Email'] = @patient.email
        map['Patient.Mobile'] = @patient.mobile
        map['Patient.Phone'] = @patient.phone
        map['Patient.Gender'] = @patient.gender
        map['Patient.FullAddress'] = @patient.full_address
        map['Patient.ShortAddress'] = @patient.short_address
        map['Patient.Address1'] = @patient.address1
        map['Patient.Address2'] = @patient.address2
        map['Patient.City'] = @patient.city
        map['Patient.State'] = @patient.state
        map['Patient.PostCode'] = @patient.postcode
        map['Patient.Country'] = @patient.country
        map['Patient.NextOfKin'] = @patient.next_of_kin
        map['Patient.Nationality'] = @patient.nationality
        map['Patient.AboriginalStatus'] = @patient.aboriginal_status

        map.merge! map_medicare_attributes
        map.merge! map_dva_attributes
        map.merge! map_ndis_attributes
        map.merge! map_hcp_attributes
        map.merge! map_hih_attributes
        map.merge! map_hi_attributes

        map
      end

      def map_medicare_attributes
        map = {}

        map['Patient.Medicare.CardNumber'] = @patient.medicare_card_number
        map['Patient.Medicare.CardIRN'] = @patient.medicare_card_irn
        map['Patient.Medicare.ReferrerName'] = @patient.medicare_referrer_name
        map['Patient.Medicare.ReferrerProviderNumber'] = @patient.medicare_referrer_provider_number
        map['Patient.Medicare.ReferralDate'] = @patient.medicare_referral_date

        map
      end

      def map_dva_attributes
        map = {}

        map['Patient.DVA.FileNumber'] = @patient.dva_file_number
        map['Patient.DVA.CardType'] = @patient.dva_card_type
        map['Patient.DVA.Hospital'] = @patient.dva_hospital
        map['Patient.DVA.WhiteCardDisability'] = @patient.dva_white_card_disability
        map['Patient.DVA.ReferrerName'] = @patient.dva_referrer_name
        map['Patient.DVA.ReferrerProviderNumber'] = @patient.dva_referrer_provider_number
        map['Patient.DVA.ReferralDate'] = @patient.dva_referral_date

        map
      end

      def map_ndis_attributes
        map = {}

        map['Patient.NDIS.ClientNumber'] = @patient.ndis_client_number
        map['Patient.NDIS.PlanStartDate'] = @patient.ndis_plan_start_date
        map['Patient.NDIS.PlanEndDate'] = @patient.ndis_plan_end_date
        map['Patient.NDIS.PlanManagerName'] = @patient.ndis_plan_manager_name
        map['Patient.NDIS.PlanManagerPhone'] = @patient.ndis_plan_manager_phone
        map['Patient.NDIS.PlanManagerEmail'] = @patient.ndis_plan_manager_email

        map
      end

      def map_hcp_attributes
        map = {}

        map['Patient.HCP.CompanyName'] = @patient.hcp_company_name
        map['Patient.HCP.ManagerName'] = @patient.hcp_manager_name
        map['Patient.HCP.ManagerPhone'] = @patient.hcp_manager_phone
        map['Patient.HCP.ManagerEmail'] = @patient.hcp_manager_email

        map
      end

      def map_hih_attributes
        map = {}

        map['Patient.HIH.Hospital'] = @patient.hih_hospital
        map['Patient.HIH.Procedure'] = @patient.hih_procedure
        map['Patient.HIH.DischargeDate'] = @patient.hih_discharge_date
        map['Patient.HIH.SurgeryDate'] = @patient.hih_surgery_date
        map['Patient.HIH.DoctorName'] = @patient.hih_doctor_name
        map['Patient.HIH.DoctorPhone'] = @patient.hih_doctor_phone
        map['Patient.HIH.DoctorEmail'] = @patient.hih_doctor_email

        map
      end

      def map_hi_attributes
        map = {}

        map['Patient.HI.CompanyName'] = @patient.hi_company_name
        map['Patient.HI.Number'] = @patient.hi_number
        map['Patient.HI.ManagerName'] = @patient.hi_manager_name
        map['Patient.HI.ManagerEmail'] = @patient.hi_manager_email
        map['Patient.HI.ManagerPhone'] = @patient.hi_manager_phone

        map
      end
    end
  end
end
