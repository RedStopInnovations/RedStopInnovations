class CleanUpUsersAndPractitionersColumns < ActiveRecord::Migration[5.0]
  def self.up
    remove_column :users, :admin
    remove_column :users, :practitioner_id

    remove_attachment :practitioners, :avatar
  end

  def self.down
    add_attachment :practitioners, :avatar
    add_column :users, :admin, :boolean, default: false
    add_column :users, :practitioner_id, :integer
  end
end
