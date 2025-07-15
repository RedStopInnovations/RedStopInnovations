class AddDeletedAtToCaseTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :case_types, :deleted_at, :datetime
  end
end
