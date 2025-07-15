class CreateEmailSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :email_settings do |t|
      t.integer :business_id
      t.boolean :status, default: true

      t.timestamps
    end
  end
end
