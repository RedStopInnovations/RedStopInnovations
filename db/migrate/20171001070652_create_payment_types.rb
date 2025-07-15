class CreatePaymentTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_types do |t|
      t.integer :business_id, null: false
      t.string :name, null: false
      t.string :type, null: false

      t.index :business_id
      t.index [:business_id, :type], unique: true
    end
  end
end
