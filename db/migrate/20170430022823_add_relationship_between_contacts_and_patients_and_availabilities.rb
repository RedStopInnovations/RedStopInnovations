class AddRelationshipBetweenContactsAndPatientsAndAvailabilities < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts_patients do |t|
      t.integer :contact_id
      t.integer :patient_id
      t.timestamps
    end
    add_index :contacts_patients, :contact_id
    add_index :contacts_patients, :patient_id

    create_table :availabilities_contacts do |t|
      t.integer :contact_id
      t.integer :availability_id
      t.timestamps
    end
    add_index :availabilities_contacts, :contact_id
    add_index :availabilities_contacts, :availability_id

    add_column :contacts, :business_id, :integer
    add_index :contacts, :business_id
    rename_column :contacts, :business, :business_name
  end
end
