module PatientAccessRestriction
  extend ActiveSupport::Concern

  def authorize_patient_access
    if need_authorize_patient_access?(current_user) &&
       !@patient.patient_accesses.where(user_id: current_user.id).exists?
      respond_to do |f|
        f.html {
          redirect_to access_disallowed_patient_url(@patient),
                      alert: 'You are not authorized to access the client.'
        }
        f.json {
          render(
            json: { message: 'You are not authorized to perform this action for this client.'},
            status: 403
          )
        }
        f.js {
          redirect_to access_disallowed_patient_url(@patient), format: 'js'
        }
        f.all {
          render text: 'You are not authorized to access the client.'
        }
      end
    end
  end

  def need_authorize_patient_access?(user)
    user.business.patient_access_enable? && (user.role_practitioner? || user.role_restricted_practitioner?)
  end
end
