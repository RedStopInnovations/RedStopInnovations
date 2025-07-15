class RecreateCommunicationsTable < ActiveRecord::Migration[5.0]
  def self.up
    drop_table :communications
    create_table :communications do |t|
      t.integer :business_id, null: false
      t.integer :practitioner_id, null: false
      t.integer :patient_id, null: false
      t.string :message_type
      t.string :category
      t.string :direction
      t.text :message

      t.timestamps
      t.index :business_id
      t.index :practitioner_id
      t.index :patient_id
      t.index [:business_id, :practitioner_id]
      t.index [:practitioner_id, :patient_id]
    end
  end

  def self.down
    drop_table :communications
    create_table :communications do |t|
      t.string :message_type
      t.string :category
      t.string :direction
      t.integer :patient_id, null: false
      t.integer :practitioner_id, null: false
      t.integer :business_id, null: false
      t.string :message

      t.timestamps
      t.index :patient_id
      t.index :practitioner_id
      t.index [:practitioner_id, :patient_id]
    end
  end
end
