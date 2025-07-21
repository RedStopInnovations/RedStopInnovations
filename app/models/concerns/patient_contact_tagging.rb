# This is not really a concern, just a extracted part from Patient model for contacts tagging.
module PatientContactTagging
  extend ActiveSupport::Concern

  included do
    PatientContact::TYPES.each do |contact_type|
      normalized_contact_type = contact_type.parameterize(separator: '_')
      assoc_name = "patient_#{normalized_contact_type}_contacts".to_sym

      # Define following associations:
      #   - patient_doctor_contacts
      #   - patient_specialist_contacts
      #   - patient_referrer_contacts
      #   - patient_invoice_to_contacts
      #   - patient_emergency_contacts
      #   - patient_other_contacts
      has_many(
        assoc_name,
        -> { where(type: contact_type) },
        class_name: 'PatientContact',
        autosave: true
      )

      # Define following methods:
      #   - doctor_contacts
      #   - specialist_contacts
      #   - referrer_contacts
      #   - invoice_to_contacts
      #   - emergency_contacts
      #   - other_contacts

      define_method "#{normalized_contact_type}_contacts" do
        Contact.where(
          id: patient_contacts.select { |pc| pc.type == contact_type }.map(&:contact_id)
        )
      end

      # Define following methods:
      #   - primary_doctor_contact
      #   - primary_specialist_contact
      #   - primary_referrer_contact
      #   - primary_invoice_to_contact
      #   - primary_emergency_contact
      #   - primary_other_contact
      # @return Contact
      define_method "primary_#{normalized_contact_type}_contact" do
        send(assoc_name).order(created_at: :asc).first.try(:contact)
      end

      contact_ids_attr = "#{normalized_contact_type}_contact_ids"

      # Define following methods:
      #   - doctor_contact_ids
      #   - specialist_contact_ids
      #   - referrer_contact_ids
      #   - invoice_to_contact_ids
      #   - emergency_contact_ids
      #   - other_contact_ids
      attr_accessor contact_ids_attr

      before_update do
        # Compare changes to create or delete patient_contacts
        current_ids = send(contact_ids_attr)
        unless current_ids.nil? || !current_ids.is_a?(Array)

          sanitized_current_ids = current_ids.select(&:present?).map(&:to_i).uniq

          prev_ids = patient_contacts.select do |pc|
            pc.type == contact_type
          end.map(&:contact_id)

          added_ids = sanitized_current_ids - prev_ids
          removed_ids = prev_ids - sanitized_current_ids

          patient_contacts.select do |pc|
            (pc.type == contact_type) && removed_ids.include?(pc.contact_id)
          end.each(&:mark_for_destruction)

          added_ids.each do |contact_id|
            patient_contacts.build(
              patient: self,
              contact_id: contact_id,
              type: contact_type
            )
          end
        end
      end

      after_create do
        contact_ids = send(contact_ids_attr)
        unless contact_ids.nil? || !contact_ids.is_a?(Array)

          sanitized_ids = contact_ids.select(&:present?).map(&:to_i).uniq

          sanitized_ids.each do |contact_id|
            patient_contacts.build(
              patient: self,
              contact_id: contact_id,
              type: contact_type
            )
          end
        end
      end
    end

    def preload_tagged_contacts
      # Set value for *_contact_ids getters
      PatientContact::TYPES.each do |contact_type|
        contact_ids_attr =
          "#{contact_type.parameterize(separator: '_')}_contact_ids".to_sym

          send(
            :"#{contact_ids_attr}=",
            patient_contacts.select do |pc|
              pc.type == contact_type
            end.map(&:contact_id)
          )
      end
    end

    has_many :patient_contacts,
            inverse_of: :patient,
            dependent: :destroy,
            autosave: true
  end
end
