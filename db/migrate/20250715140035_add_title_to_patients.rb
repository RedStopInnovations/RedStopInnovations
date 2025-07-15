class AddTitleToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :title, :string
  end
end
