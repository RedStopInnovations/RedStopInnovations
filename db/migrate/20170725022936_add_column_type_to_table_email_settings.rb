class AddColumnTypeToTableEmailSettings < ActiveRecord::Migration[5.0]
  def change
  	add_column :email_settings, :setting_type, :string

  	add_index :email_settings, [:business_id, :setting_type], unique: true
  end
end
