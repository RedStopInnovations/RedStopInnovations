class CreateReferralsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :referrals do |t|
      t.integer :availability_type_id
      t.string :profession
      t.integer :practitioner_id
      t.integer :patient_id
      t.integer :business_id

      t.string :status

      t.text :patient_attrs

      t.string :name
      t.string :phone
      t.string :email
      t.timestamps

      t.index :availability_type_id
      t.index :practitioner_id
    end
  end
end
