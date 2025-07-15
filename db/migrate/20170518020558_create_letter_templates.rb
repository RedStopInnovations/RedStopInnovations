class CreateLetterTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :letter_templates do |t|
      t.integer :business_id, null: false
      t.string :name, null: false
      t.text :content
      t.string :email_subject

      t.timestamps
      t.index :business_id
    end
  end
end
