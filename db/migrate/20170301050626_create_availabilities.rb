class CreateAvailabilities < ActiveRecord::Migration[5.0]
  def change
    create_table :availabilities do |t|
      t.string :name
      t.datetime :start_time
      t.datetime :end_time
      t.integer :max_appointment
      t.integer :service_radius
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :postcode
      t.string :country
      t.float :latitude
      t.float :longitude
      t.integer :repeat_frequency, :default => 0
      t.integer :repeat_total, :default => 0
      t.references :practitioner, foreign_key: true

      t.timestamps
    end
  end
end
