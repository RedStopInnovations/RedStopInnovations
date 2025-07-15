class ChangeCoreplusRefToString < ActiveRecord::Migration[5.0]
  def change
    change_column :coreplus_records, :reference_id, :string
  end
end
