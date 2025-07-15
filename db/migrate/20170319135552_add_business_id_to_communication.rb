class AddBusinessIdToCommunication < ActiveRecord::Migration[5.0]
  def change
    add_column :communications, :business_id, :integer
    add_index :communications, :business_id
  end
end
