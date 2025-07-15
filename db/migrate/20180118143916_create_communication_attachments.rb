class CreateCommunicationAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :communication_attachments do |t|
      t.integer :communication_template_id, null: false
      t.attachment :attachment
    end
  end
end
