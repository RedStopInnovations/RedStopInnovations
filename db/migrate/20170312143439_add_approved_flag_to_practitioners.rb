class AddApprovedFlagToPractitioners < ActiveRecord::Migration[5.0]
  def change
    change_table :practitioners do |t|
      t.boolean :approved, default: false
      t.index :approved
    end
  end
end
