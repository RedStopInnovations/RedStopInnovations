class AddNameColumnsToUsers < ActiveRecord::Migration[5.0]
  def change
    change_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_name
    end
  end
end
