class CreateAppEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :app_events do |t|
      t.string :event_type, null: false, index: true
      t.string :ip
      t.integer :associated_business_id, index: true
      t.jsonb :extra
      t.datetime :created_at, null: false
    end
  end
end
