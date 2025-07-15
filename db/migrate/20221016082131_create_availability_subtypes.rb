class CreateAvailabilitySubtypes < ActiveRecord::Migration[6.1]
  def change
    create_table :availability_subtypes do |t|
      t.integer :business_id, null: false, index: true
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
