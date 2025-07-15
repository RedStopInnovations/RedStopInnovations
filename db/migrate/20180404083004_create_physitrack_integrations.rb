class CreatePhysitrackIntegrations < ActiveRecord::Migration[5.0]
  def change
    create_table :physitrack_integrations do |t|
      t.integer :business_id, null: false
      t.boolean :enabled, null: false
      t.timestamps

      t.index :business_id, unique: true
    end
  end
end
