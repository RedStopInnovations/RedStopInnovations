class CreateAppointmentTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :appointment_types do |t|
      t.references :business, null: false

      t.string :name
      t.text :description
      t.string :item_number
      t.integer :duration
      t.integer :price
      t.timestamps
    end
  end
end
