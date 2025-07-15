class CreateSubscriptionDiscounts < ActiveRecord::Migration[5.0]
  def change
    create_table :subscription_discounts do |t|
      t.string :name
      t.string :discount_type
      t.references :business
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.datetime :from_date
      t.datetime :end_date
      t.boolean :expired

      t.timestamps
    end
  end
end
