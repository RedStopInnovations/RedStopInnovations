class AddPractitionerFlagToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :is_practitioner, :boolean, default: true
    add_index :users, :is_practitioner
  end
end
