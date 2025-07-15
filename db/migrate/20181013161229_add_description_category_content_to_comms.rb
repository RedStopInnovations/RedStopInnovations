class AddDescriptionCategoryContentToComms < ActiveRecord::Migration[5.0]
  def change
    change_table :communications do |t|
      t.text :description
      t.text :content
    end
  end
end
