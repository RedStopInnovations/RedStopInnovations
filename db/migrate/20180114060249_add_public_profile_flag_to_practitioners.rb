class AddPublicProfileFlagToPractitioners < ActiveRecord::Migration[5.0]
  def change
    change_table :practitioners do |t|
      t.boolean :public_profile, default: true
      t.index [:approved, :public_profile, :active],
              name: :idx_practitioners_approved_public_profile_active
    end
  end
end
