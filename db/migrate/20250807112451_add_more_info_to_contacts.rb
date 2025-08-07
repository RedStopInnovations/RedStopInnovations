class AddMoreInfoToContacts < ActiveRecord::Migration[7.1]
  def change
    change_table :contacts do |t|
      t.string :profession
      t.string :provider_number
    end
  end
end
