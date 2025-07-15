class AddAttachmentAvatarToPractitioners < ActiveRecord::Migration[5.0]
  def self.up
    change_table :practitioners do |t|
      t.attachment :avatar
    end
  end

  def self.down
    remove_attachment :practitioners, :avatar
  end
end
