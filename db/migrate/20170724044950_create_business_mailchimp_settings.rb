class CreateBusinessMailchimpSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :business_mailchimp_settings do |t|
      t.integer :business_id, null: false
      t.string :list_name
      t.string :api_key
      t.timestamps
    end
  end
end
