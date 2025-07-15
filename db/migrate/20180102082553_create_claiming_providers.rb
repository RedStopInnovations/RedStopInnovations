class CreateClaimingProviders < ActiveRecord::Migration[5.0]
  def change
    create_table :claiming_providers do |t|
      t.integer :auth_group_id, null: false # Internal claiming_auth_groups's ID
      t.string :name, null: false
      t.string :provider_number, null: false

      t.timestamps
    end
  end
end
