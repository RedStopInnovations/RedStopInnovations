class CreateBusinessesPatients < ActiveRecord::Migration[5.0]
  def change
    create_table :businesses_patients do |t|
      t.references :patient, null: false
      t.references :business, null: false
    end
  end
end
