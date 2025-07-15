class CreateTreatments < ActiveRecord::Migration[5.0]
  def change
    create_table :treatments do |t|
      t.string :title
      t.boolean :draft
      t.text :note
      t.references :appointment, null: false

      t.timestamps
    end
  end
end
