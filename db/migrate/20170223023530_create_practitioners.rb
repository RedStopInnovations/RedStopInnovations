class CreatePractitioners < ActiveRecord::Migration[5.0]
  def change
    create_table :practitioners do |t|
      t.references :business
      t.string :first_name
      t.string :last_name
      t.string :profession
      t.string :ahpra
      t.string :medicare
      t.string :phone
      t.string :mobile
      t.string :website
      t.string :email
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :postcode
      t.string :country
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
  end
end
