class CreateContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
      t.string :business
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :mobile
      t.string :fax
      t.string :email
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :postcode
      t.string :country

      t.timestamps
    end
  end
end
