class FixCommunicationTemplatesTable < ActiveRecord::Migration[5.0]
  def change
    change_table :communication_templates do |t|
      t.string :name, null: false, default: ''
      t.string :template_id, null: false, default: ''
      t.remove :template_type
      t.remove :status
      t.remove :sent_period

      t.index [:business_id, :template_id], name: :index_business_id_and_template_id
    end
  end
end
