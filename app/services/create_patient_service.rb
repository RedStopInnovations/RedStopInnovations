class CreatePatientService
  attr_reader :business, :form_request, :author

  # @param Business business
  # @param CreatePatientForm form_request
  # @param User author
  def call(business, form_request, author)
    @business = business
    @form_request = form_request
    @author = author

    patient = build_patient

    patient.save!

    ::Webhook::Worker.perform_later(patient.id, WebhookSubscription::PATIENT_CREATED)

    # Send confirmation email to patient
    if patient.email? && patient.reminder_enable? &&
      business.communication_template_enabled?(CommunicationTemplate::TEMPLATE_ID_NEW_PATIENT_CONFIRMATION)
      PatientMailer.new_patient_confirmation(patient).deliver_later
    end

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

    # Grant patient access
    PatientAccess.create!(
      user_id: author.id,
      patient_id: patient.id
    )

    patient
  end

  private

  def build_patient
    patient = Patient.new(form_request.attributes.slice(
      :title,
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
      :extra_invoice_info,
      :next_of_kin,
      :nationality,
      :aboriginal_status,
      :spoken_languages,
      :accepted_privacy_policy,

      :tag_ids
    ))

    patient.business_id = business.id

    patient
  end
end
