class AddRoutingStatusToAvailability < ActiveRecord::Migration[5.2]
  def change
    add_column :availabilities, :routing_status, :string # ok, error, not_found
  end
end
