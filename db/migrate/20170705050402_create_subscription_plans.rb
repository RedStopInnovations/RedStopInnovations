class CreateSubscriptionPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :subscription_plans do |t|
      t.string :name
      t.string :description
      t.decimal :appointment_price, precision: 10, scale: 2, default: 0
      t.decimal :sms_price, precision: 10, scale: 2, default: 0
      t.decimal :routes_price, precision: 10, scale: 2, default: 0
      
      t.timestamps
    end
  end
end