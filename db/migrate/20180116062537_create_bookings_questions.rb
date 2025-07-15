class CreateBookingsQuestions < ActiveRecord::Migration[5.0]
  def change
    create_table :bookings_questions do |t|
      t.integer :business_id, null: false, index: true
      t.integer :order, null: false
      t.boolean :required, null: false, default: false
      t.text :title
      t.string :type, null: false # Text, Checkboxes, Radiobuttons
      t.text :answers
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
