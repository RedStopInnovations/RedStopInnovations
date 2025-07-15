class CreatePatients < ActiveRecord::Migration[5.0]
  def change
    create_table :patients do |t|
      t.string :first_name
      t.string :last_name
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
      t.date :dob
      t.string :gender
      t.string :referral_info
      t.string :doctor
      t.string :reference
      t.string :invoice_to
      t.string :invoice_email
      t.string :invoice_extra
      t.timestamps
    end
  end
end
