class CreateNookalRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :nookal_records do |t|
      t.integer  :business_id,    null: false
      t.integer  :reference_id,   null: false   # ID from Nookal

      t.integer  :internal_id,    null: false
      t.string   :resource_type,  null: false

      t.datetime :last_synced_at, null: false

      t.index :business_id, name: :nookal_records_business_id
      t.index [:resource_type, :internal_id], name: :nookal_records_resource_type_internal_id
      t.index [:resource_type, :reference_id], name: :nookal_records_resource_type_reference_id
      t.index [:business_id, :resource_type, :reference_id], name: :nookal_records_business_id_resource_type_reference_id
    end
  end
end
