class CreateTaxes < ActiveRecord::Migration[5.0]
  def change
    create_table :taxes do |t|
      t.string  :name
      t.float   :rate
      t.integer :business_id

      t.timestamps
    end

    add_index :taxes, :business_id
  end
end
