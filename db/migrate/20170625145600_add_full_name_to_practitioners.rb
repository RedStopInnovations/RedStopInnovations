class AddFullNameToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :full_name, :string, after: :last_name
  end
end
