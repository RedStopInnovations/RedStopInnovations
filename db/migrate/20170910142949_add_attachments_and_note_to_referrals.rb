class AddAttachmentsAndNoteToReferrals < ActiveRecord::Migration[5.0]
  def self.up
    change_table :referrals do |t|
      t.attachment :attachment
      t.text :notes
    end
  end

  def self.down
    remove_attachment :referrals, :attachment
    remove_column :referrals, :notes
  end
end
