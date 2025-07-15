class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|
      t.references :subscription_plan
      t.references :business
      t.datetime :trial_start
      t.datetime :trial_end
      t.datetime :billing_start
      t.datetime :billing_end
      t.string :status
      t.string :stripe_customer_id
      t.string :card_last4
      t.timestamps
    end
  end
end
