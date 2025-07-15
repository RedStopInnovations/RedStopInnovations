class CreatePatientAccessSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_access_settings do |t|
      t.integer :business_id, null: false
      t.boolean :enable, default: false
      t.index :business_id, unique: true
    end
  end
end
