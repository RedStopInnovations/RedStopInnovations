class AddSlugToPractitioners < ActiveRecord::Migration[5.0]
  def change
    change_table :practitioners do |t|
      t.string :slug, null: false, default: ''
      t.index :slug
    end
  end
end
