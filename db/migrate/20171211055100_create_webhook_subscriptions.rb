class CreateWebhookSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_subscriptions do |t|
      t.integer :business_id, null: false, index: true
      t.integer :user_id, null: false, index: true
      t.string :event, null: false, index: true
      t.string :target_url, null: false
      t.string :method
      t.jsonb :event_params
      t.boolean :active, default: true, index: true
      t.timestamps
    end
  end
end
