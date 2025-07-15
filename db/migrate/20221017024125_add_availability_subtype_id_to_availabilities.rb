class AddAvailabilitySubtypeIdToAvailabilities < ActiveRecord::Migration[6.1]
  def change
    add_column :availabilities, :availability_subtype_id, :integer
  end
end
