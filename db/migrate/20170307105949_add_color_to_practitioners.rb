class AddColorToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :color, :string, :null => false, :default => "#3a87ad"
  end
end
