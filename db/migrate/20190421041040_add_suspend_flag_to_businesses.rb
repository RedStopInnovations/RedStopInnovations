class AddSuspendFlagToBusinesses < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :suspended, :boolean, default: false
  end
end
