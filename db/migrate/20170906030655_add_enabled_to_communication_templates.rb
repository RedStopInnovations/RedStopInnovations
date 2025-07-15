class AddEnabledToCommunicationTemplates < ActiveRecord::Migration[5.0]
  def change
    add_column :communication_templates, :enabled, :boolean, default: true
  end
end
