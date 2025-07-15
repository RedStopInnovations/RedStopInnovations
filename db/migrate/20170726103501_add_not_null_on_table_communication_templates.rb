class AddNotNullOnTableCommunicationTemplates < ActiveRecord::Migration[5.0]
  def change
  	change_column :communication_templates, :business_id, :integer, null: false
  	add_index :communication_templates, :business_id
  end
end
