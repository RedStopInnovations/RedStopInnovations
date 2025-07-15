class AddHealthInsuranceRebateFlagToBillableItems < ActiveRecord::Migration[5.0]
  def change
    change_table :billable_items do |t|
      t.boolean :health_insurance_rebate, default: false

      t.index :health_insurance_rebate
    end
  end
end
