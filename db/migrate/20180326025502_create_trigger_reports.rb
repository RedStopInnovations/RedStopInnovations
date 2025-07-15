class CreateTriggerReports < ActiveRecord::Migration[5.0]
  def change
    create_table :trigger_reports do |t|
      t.string :trigger_source_id, null: false
      t.integer :trigger_source_type, null: false
      t.integer :mentions_count, null: false, default: 0
      t.integer :patients_count, null: false, default: 0
      t.timestamps

      t.index [:trigger_source_id, :trigger_source_type], name: 'idx_trigger_reports_source_id_type'
    end
  end
end
