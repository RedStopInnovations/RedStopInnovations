class AddActiveToBusinesses < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :active, :boolean, default: :false

    add_index :businesses, :active
  end
end
