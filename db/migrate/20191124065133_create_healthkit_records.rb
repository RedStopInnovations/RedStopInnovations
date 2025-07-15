class CreateHealthkitRecords < ActiveRecord::Migration[5.0]
  def change

    create_table :healthkit_records do |t|
      t.integer  :business_id,    null: false
      t.integer  :reference_id,   null: false   # ID from Healthkit

      t.integer  :internal_id,    null: false
      t.string   :resource_type,  null: false

      t.datetime :last_synced_at, null: false

      t.index :business_id, name: :healthkit_records_business_id
      t.index [:resource_type, :internal_id], name: :healthkit_records_resource_type_internal_id
      t.index [:resource_type, :reference_id], name: :healthkit_records_resource_type_reference_id
      t.index [:business_id, :resource_type, :reference_id], name: :healthkit_records_business_id_resource_type_reference_id
    end
  end
end
