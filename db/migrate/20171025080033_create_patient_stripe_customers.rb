class CreatePatientStripeCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_stripe_customers do |t|
      t.integer :patient_id, null: false
      t.string :stripe_customer_id, null: false
      t.string :stripe_owner_account_id, null: false
      t.string :card_last4, null: false

      t.timestamps

      t.index :patient_id
    end
  end
end
