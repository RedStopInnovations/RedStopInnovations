class AddInternalNoteToReferrals < ActiveRecord::Migration[5.2]
  def change
    add_column :referrals, :internal_note, :text, nullable: true
  end
end
