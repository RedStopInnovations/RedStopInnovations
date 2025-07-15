class AddBusinessIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :business
    add_reference :users, :practitioner
  end
end
