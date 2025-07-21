module Export
  class Patients
    attr_reader :business, :options

    def self.make(business, options)
      new(business, options)
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'ID', 'First name', 'Last name', 'Email', 'Phone', 'Mobile', 'Dob', 'Gender',
          'Address line 1', 'Address line 2', 'City', 'State', 'Postcode', 'Country',
          'Important notification',
          'Medicare', 'DVA', 'NDIS', 'Home care package', 'Hospital in home', 'Health insurance', 'STRC',
          'Reminder enable',
          'Archived',
          'Creation',
          "Last appointment date",
          "Associated contact ID",
          "Invoice to contact",
          "Referrer contact",
          "Doctor contact",
          "Specialist contact",
          "Emergency contact",
          "Other contact",
          "Privacy policy acceptance",
          "Contact ID numbers",
          "Next of kin",
          "Additional info"
        ]

        patients_query.includes(:patient_contacts, id_numbers: [:contact]).find_each do |patient|
          associated_contact_ids_cell = if patient.associated_contact_ids.present?
            patient.associated_contact_ids.split(',').uniq.join(',')
          end

          invoice_to_contacts_cell = patient.invoice_to_contacts.map(&:business_name).join(';')
          referrer_contacts_cell = patient.referrer_contacts.map(&:business_name).join(';')
          doctor_contacts_cell = patient.doctor_contacts.map(&:business_name).join(';')
          specialist_contacts_cell = patient.specialist_contacts.map(&:business_name).join(';')
          emergency_contacts_cell = patient.emergency_contacts.map(&:business_name).join(';')
          other_contacts_cell = patient.other_contacts.map(&:business_name).join(';')

          privacy_policy_acceptance_cell =
            if patient.accepted_privacy_policy.nil?
              'No response'
            elsif patient.accepted_privacy_policy === true
              'Accepted'
            elsif patient.accepted_privacy_policy === false
              'Rejected'
            end

          contact_id_numbers_cell =
            patient.id_numbers.map do |idn|
              "#{idn.contact.business_name.to_s.strip}:#{idn.id_number.to_s.strip}"
            end.join(';')

          csv << [
            patient.id,
            patient.first_name,
            patient.last_name,
            patient.email,
            patient.phone,
            patient.mobile,
            patient.dob,
            patient.gender,
            patient.address1,
            patient.address2,
            patient.city,
            patient.state,
            patient.postcode,
            patient.country,
            patient.important_notification.presence,
            medicare_details_for_csv(patient),
            dva_details_for_csv(patient),
            ndis_details_for_csv(patient),
            hcp_details_for_csv(patient),
            hih_details_for_csv(patient),
            hi_details_for_csv(patient),
            strc_details_for_csv(patient),
            patient.reminder_enable? ? 'Yes' : 'No',
            patient.archived? ? 'Yes' : 'No',
            patient.created_at.strftime('%Y-%m-%d'),
            patient.last_appointment_start_time&.strftime('%Y-%m-%d'),
            associated_contact_ids_cell,
            invoice_to_contacts_cell,
            referrer_contacts_cell,
            doctor_contacts_cell,
            specialist_contacts_cell,
            emergency_contacts_cell,
            other_contacts_cell,
            privacy_policy_acceptance_cell,
            contact_id_numbers_cell,
            patient.next_of_kin,
            patient.general_info
          ]
        end
      end
    end

    def as_xero_import_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          '*ContactName',
          'EmailAddress',
          'FirstName',
          'LastName',
          'POAddressLine1',
          'POAddressLine2',
          'POCity',
          'PORegion',
          'POPostalCode',
          'POCountry',
          'PhoneNumber',
          'FaxNumber',
          'MobileNumber'
        ]

        patients_query.find_each do |patient|
          csv << [
            patient.full_name,
            patient.email,
            patient.first_name,
            patient.last_name,
            patient.address1.presence,
            patient.address2.presence,
            patient.city,
            patient.state,
            patient.postcode,
            patient.country,
            patient.phone.presence,
            patient.fax.presence,
            patient.mobile.presence,
          ]
        end
      end
    end
    private

    def patients_query
      query = business.patients.left_joins(:patient_contacts)

      if options[:create_date_start].present?
        query = query.where("patients.created_at >= ?", options[:create_date_start].beginning_of_day)
      end

      if options[:create_date_end].present?
        query = query.where("patients.created_at <= ?", options[:create_date_end].end_of_day)
      end

      if options[:contact_ids].present? && options[:contact_ids].is_a?(Array)
        query = query.where('patient_contacts.contact_id' => options[:contact_ids])
      end

      unless options[:include_archived]
        query = query.where('patients.archived_at IS NULL')
      end

      query = query.joins('
        LEFT JOIN (
          SELECT patient_id, MAX(appointments.start_time) AS last_appointment_start_time
            FROM appointments
          WHERE appointments.cancelled_at IS NULL AND appointments.deleted_at IS NULL
          GROUP BY patient_id
        ) APPT on APPT.patient_id = patients.id
      ')
      query.select('patients.*, APPT.last_appointment_start_time, STRING_AGG(patient_contacts.contact_id::TEXT, \',\') AS associated_contact_ids')
        .group('patients.id, APPT.last_appointment_start_time')
    end

    def medicare_details_for_csv(patient)
      return unless patient.medicare_details.present?
      info = {
        'Card number' => patient.medicare_card_number,
        'IRN' => patient.medicare_card_irn,
        'Referrer name' => patient.medicare_referrer_name,
        'Referrer provider number' => patient.medicare_referrer_provider_number,
        'Referral date' => patient.medicare_referral_date
      }

      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end

    def dva_details_for_csv(patient)
      return unless patient.dva_details.present?
      info = {
        'File number' => patient.dva_file_number,
        'Hospital' => patient.dva_hospital,
        'Card type' => patient.dva_card_type,
        'Referrer name' => patient.dva_referrer_name,
        'Referrer provider number' => patient.dva_referrer_provider_number,
        'Referral date' => patient.dva_referral_date
      }

      if patient.dva_card_type == 'White Card'
        info['White card disability'] = patient.dva_white_card_disability
      end

      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end

    def ndis_details_for_csv(patient)
      return unless patient.ndis_details.present?
      info = {
        'NDIS client number' => patient.ndis_client_number,
        'Plan start date' => patient.ndis_plan_start_date,
        'Plan end date' => patient.ndis_plan_end_date,
        'Manager name' => patient.ndis_plan_manager_name,
        'Manager phone' => patient.ndis_plan_manager_phone,
        'Manager email' => patient.ndis_plan_manager_email
      }

      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end

    def hcp_details_for_csv(patient)
      return unless patient.hcp_details.present?

      info = {
        'Company name' => patient.hcp_company_name,
        'Manager name' => patient.hcp_manager_name,
        'Manager phone' => patient.hcp_manager_phone,
        'Manager email' => patient.hcp_manager_email
      }

      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end

    def hih_details_for_csv(patient)
      return unless patient.hih_details.present?

      info = {
        'Hospital' => patient.hih_hospital,
        'Procedure' => patient.hih_procedure,
        'Discharge date' => patient.hih_discharge_date,
        'Surgery date' => patient.hih_surgery_date,
        'Doctor name' => patient.hih_doctor_name,
        'Doctor phone' => patient.hih_doctor_phone,
        'Doctor email' => patient.hih_doctor_email
      }

      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end

    def hi_details_for_csv(patient)
      return unless patient.hi_details.present?

      info = {
        'Health insurer name' => patient.hi_company_name,
        'Member number' => patient.hi_number,
        'Manager name' => patient.hi_manager_name,
        'Manager email' => patient.hi_manager_email,
        'Manager phone' => patient.hi_manager_phone,
      }
      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end

    def strc_details_for_csv(patient)
      return unless patient.strc_details.present?

      info = {
        'Company name' => patient.strc_company_name,
        'Company phone' => patient.strc_company_phone,
        'Manager name' => patient.strc_invoice_to_name,
        'Manager email' => patient.strc_invoice_to_email,
      }
      info.map do |key, val|
        "#{key}: #{val}"
      end.join("\n")
    end
  end
end
