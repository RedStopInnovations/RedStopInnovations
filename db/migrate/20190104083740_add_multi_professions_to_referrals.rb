class AddMultiProfessionsToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :professions, :text
  end
end
