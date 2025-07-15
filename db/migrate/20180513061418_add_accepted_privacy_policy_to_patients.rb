class AddAcceptedPrivacyPolicyToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :accepted_privacy_policy, :boolean
  end
end
