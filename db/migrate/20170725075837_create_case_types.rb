class CreateCaseTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :case_types do |t|
      t.string :title
      t.integer :business_id, null: :fasle
      t.timestamps
    end
  end
end
