class AddRecipientColumnToCommunications < ActiveRecord::Migration[5.0]
  def change
    add_column :communications, :recipient_type, :string, index: true
    add_column :communications, :recipient_id, :integer, index: true
    add_column :communications, :linked_patient_id, :integer, index: true
  end
end
