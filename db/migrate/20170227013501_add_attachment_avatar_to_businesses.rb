class AddAttachmentAvatarToBusinesses < ActiveRecord::Migration[5.0]
  def self.up
    change_table :businesses do |t|
      t.attachment :avatar
    end
  end

  def self.down
    remove_attachment :businesses, :avatar
  end
end
