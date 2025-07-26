class AddReadStatusToCommunications < ActiveRecord::Migration[7.1]
  def change
    add_column :communications, :read, :boolean, default: true, null: false
  end
end
