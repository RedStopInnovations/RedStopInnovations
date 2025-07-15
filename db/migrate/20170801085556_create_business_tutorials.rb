class CreateBusinessTutorials < ActiveRecord::Migration[5.0]
  def change
    create_table :business_tutorials do |t|
      t.integer :business_id, null: :false
      t.text :lessons
      t.integer :status
      t.timestamps

      t.index :business_id
    end


  end
end
