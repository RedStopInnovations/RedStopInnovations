class AddUserIdToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :user_id, :integer
    add_index :practitioners, :user_id
  end
end
