class AddSettingsToCommunicationTemplates < ActiveRecord::Migration[6.1]
  def change
    add_column :communication_templates, :settings, :json, default: {}
  end
end
