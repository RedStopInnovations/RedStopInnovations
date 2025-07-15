class AddActiveToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :active, :boolean, default: true, null: false
    add_index :practitioners, :active
  end
end
