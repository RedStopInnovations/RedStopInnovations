class CreateCommunicationTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :communication_templates do |t|
    	t.integer :business_id
    	t.text :email_subject
    	t.text :content
    	t.text :sent_period
    	t.string :template_type
    	t.boolean :status, default: true

      t.timestamps
    end
  end
end
