class AddSourceToCommunication < ActiveRecord::Migration[5.0]
  def change
    add_column :communications, :source_id, :integer
    add_column :communications, :source_type, :string
  end
end
