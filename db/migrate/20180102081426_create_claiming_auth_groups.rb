class CreateClaimingAuthGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :claiming_auth_groups do |t|
      t.integer :business_id, null: false
      t.string :claiming_auth_group_id, null: false # ID from Claiming.com.au
      t.string :claiming_minor_id, null: false # Minor ID from Claiming.com.au

      t.index :business_id
      t.timestamps
    end
  end
end
