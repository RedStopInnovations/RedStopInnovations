class CreateStripeInfos < ActiveRecord::Migration[5.0]
  def change
    create_table :stripe_infos do |t|
      t.string :stripe_customer_id
      t.integer :patient_id

      t.timestamps
    end
  end
end
