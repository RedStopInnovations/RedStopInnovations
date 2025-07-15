class CreateUserPreferences < ActiveRecord::Migration[6.1]
  def change
    create_table :user_preferences do |t|
      t.integer :user_id, null: false, index: true
      t.string :key, null: false
      t.string :value_type, null: false, default: 'string'
      t.text :value

      t.index [:user_id, :key], unique: true
    end
  end
end
