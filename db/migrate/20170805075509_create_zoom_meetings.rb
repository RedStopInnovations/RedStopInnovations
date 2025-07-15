class CreateZoomMeetings < ActiveRecord::Migration[5.0]
  def change
    create_table :zoom_meetings do |t|
      t.integer :practitioner_id, null: false, index: true
      t.integer :appointment_id, null: false, index: true

      t.string :zoom_meeting_id, null: false
      t.string :zoom_host_id, null: false

      t.integer :duration, null: false
      t.datetime :start_time, null: false
      t.string :start_timezone, null: false

      t.string :join_url, null: false
      t.text :start_url, null: false
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
