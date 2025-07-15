class ModifyCommunications < ActiveRecord::Migration[5.0]
  def change
    change_column :communications, :patient_id, :integer, null: true
    change_column :communications, :practitioner_id, :integer, null: true
    add_column :communications, :contact_id, :integer, null: true

    add_index :communications, :contact_id
  end
end
