class MergePatientsService
  # @param target_patient Patient
  # @param selected_patients Array
  # @param current_user User
  def call(target_patient, selected_patients, current_user)
    @target_patient = target_patient
    @selected_patients = selected_patients.sort_by(&:updated_at).reverse
    @current_user = current_user

    @merge_history = MergeResourcesHistory.new(
      resource_type: Patient.name,
      author_id: current_user.id,
      target_resource_id: @target_patient.id,
      merged_resource_ids: @selected_patients.map(&:id),
      meta: {
        target_resource: @target_patient.attributes,
        merged_resources: @selected_patients.map(&:attributes)
      }
    )

    ActiveRecord::Base.transaction do
      merge_details_info
      merge_appoinments
      merge_invoices
      merge_payments
      merge_attachments
      merge_treatment_notes
      merge_letters
      merge_contacts
      merge_communications
      merge_accesses
      merge_account_statements # TODO: patient_id filter of account statements's options
      merge_cases
      merge_id_numbers
      merge_waitlist
      merge_reviews
      merge_referrals
      delete_merged_patients
      @merge_history.save!
    end
  end

  private

  def selected_patient_ids
    @selected_patient_ids ||= @selected_patients.map(&:id)
  end

  def merge_details_info
    %i[
      email phone mobile dob gender
      address1 address2 city state postcode country
      general_info next_of_kin aboriginal_status
      medicare_details dva_details ndis_details hcp_details
      hih_details hi_details
    ].each do |attr|
      if @target_patient[attr].blank?
        # Use the attribute of the patient has latest update
        @target_patient[attr] =
          @selected_patients.map(&:"#{attr}").find(&:present?)
      end
    end

    @target_patient.save!(validate: false)
  end

  def merge_appoinments
    Appointment.with_deleted.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_invoices
    Invoice.with_deleted.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_payments
    Payment.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_attachments
    PatientAttachment.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_treatment_notes
    Treatment.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_letters
    PatientLetter.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_contacts
    PatientContact.where(patient_id: selected_patient_ids).each do |pa|
      pa.update(
        patient_id: @target_patient.id,
        updated_at: Time.current
      )
    end
  end

  def merge_communications
    Communication.where(
        recipient_type: Patient.name,
        recipient_id: selected_patient_ids)
      .update_all(
        recipient_id: @target_patient.id
      )

    Communication.where(linked_patient_id: selected_patient_ids).update_all(
      linked_patient_id: @target_patient.id
    )
  end

  def merge_account_statements
    AccountStatement.where(
      source_type: Patient.name,
      source_id: selected_patient_ids
    ).update_all(
      source_id: @target_patient.id
    )
  end

  def merge_cases
    PatientCase.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_id_numbers
    PatientIdNumber.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_accesses
    PatientAccess.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_waitlist
    WaitList.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_reviews
    Review.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def merge_referrals
    Referral.where(patient_id: selected_patient_ids).update_all(
      patient_id: @target_patient.id
    )
  end

  def delete_merged_patients
    @selected_patients.each do |patient|
      patient.destroy_by_author(@current_user)
    end
  end
end
