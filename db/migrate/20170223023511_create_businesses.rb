class CreateBusinesses < ActiveRecord::Migration[5.0]
  def change
    create_table :businesses do |t|
      t.string :name
      t.string :phone
      t.string :mobile
      t.string :website
      t.string :fax
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
