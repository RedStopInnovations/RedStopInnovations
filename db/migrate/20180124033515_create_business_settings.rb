class CreateBusinessSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :business_settings do |t|
      t.string :storage_url
      t.integer :business_id, index: true
    end
  end
end
