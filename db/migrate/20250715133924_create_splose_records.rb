class CreateSploseRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :splose_records do |t|
      t.integer  :business_id,   null: false
      t.string  :reference_id,   null: false   # ID in Splose API

      t.integer  :internal_id,   null: false
      t.string   :resource_type,   null: false

      t.datetime :last_synced_at,   null: false

      t.index :business_id, name: :splose_records_business_id
      t.index [:resource_type, :internal_id], name: :splose_records_resource_type_internal_id
      t.index [:resource_type, :reference_id], name: :splose_records_resource_type_reference_id
    end

  end
end
