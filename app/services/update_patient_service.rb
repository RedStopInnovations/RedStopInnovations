class UpdatePatientService
  attr_reader :business, :patient, :form_request, :author

  # @param Patient patient
  # @param UpdatePatientForm form_request
  # @param User author
  def call(patient, form_request, author)
    @business = patient.business
    @patient = patient
    @form_request = form_request
    @author = author

    update_patient

    # Add patient email to Mailchimp list if enabled
    if patient.email? && business.mailchimp_list_sync_ready?
      BusinessMailchimpSyncPatients.perform_later(
        business,
        patient,
        {
          destroy: false,
          email: patient.email
        }
      )
    end

    # Discover Medipass member
    # if App::MEDIPASS_ENABLE
    #   DiscoveryMedipassMemberJob.perform_later(patient.id)
    # end

    # Grant patient access if not granted
    unless PatientAccess.exists?(user_id: author.id, patient_id: patient.id)
      PatientAccess.create!(
        user_id: author.id,
        patient_id: patient.id
      )
    end

    patient
  end

  private

  def update_patient
    patient.assign_attributes(form_request.attributes.slice(
      :first_name,
      :last_name,
      :dob,
      :gender,
      :phone,
      :mobile,
      :email,

      :address1,
      :address2,
      :city,
      :state,
      :postcode,
      :country,

      :reminder_enable,
      :general_info,
      :next_of_kin,
      :nationality,
      :aboriginal_status,
      :spoken_languages,
      :accepted_privacy_policy,

      :doctor_contact_ids,
      :specialist_contact_ids,
      :referrer_contact_ids,
      :invoice_to_contact_ids,
      :other_contact_ids
    ))

    patient.save!

    patient
  end
end
