class AddBusinessIdToTreatments < ActiveRecord::Migration[7.1]
  def change
    change_table :treatments do |t|
      t.integer :business_id, null: false, default: 0, index: true
    end
  end
end
