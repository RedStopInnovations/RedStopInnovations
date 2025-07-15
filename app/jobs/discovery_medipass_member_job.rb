class DiscoveryMedipassMemberJob < ApplicationJob
  def perform(patient_id)
    patient = Patient.find(patient_id)
    result = DiscoveryMedipassMember.new.call(patient)

    if result.success
      patient.update_column(:medipass_member_id, result.member_id)
    elsif patient.medipass_member_id?
      patient.update_column(:medipass_member_id, nil)
    end
  end
end
