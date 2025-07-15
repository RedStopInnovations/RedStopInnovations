class CreateEmergencies < ActiveRecord::Migration[5.0]
  def change
    create_table :emergencies do |t|
      t.string :profession
      t.string :suburb
      t.string :postcode
      t.string :detail
      t.string :name
      t.string :phone
      t.string :mobile
      t.string :email
      t.integer :number
      t.integer :distance

      t.timestamps
    end
  end
end
