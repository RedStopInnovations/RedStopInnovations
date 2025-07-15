class CreateSeopages < ActiveRecord::Migration[5.0]
  def change
    create_table :seopages do |t|      
    	t.string :professtion, null: false
			t.references :service, references: :tag, null: false
			t.string :city, null: false
			t.string :page_title, null: false
			t.string :page_description, null: false
			t.string :content, null: false

      t.timestamps
    end
  end
end
