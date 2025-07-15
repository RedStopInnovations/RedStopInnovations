class CreateReceptionists < ActiveRecord::Migration[5.0]
  def change
    create_table :receptionists do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :email, null: false
      t.integer :user_id
      t.timestamps

      t.index :user_id
    end
  end
end
