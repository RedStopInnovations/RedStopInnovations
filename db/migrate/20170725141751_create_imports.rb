class CreateImports < ActiveRecord::Migration[5.0]
  def change
    create_table :imports do |t|
      t.string :name
      t.datetime :date_added
      t.references :business
      t.string :uploaded_file_name
      t.timestamps
    end
  end
end
