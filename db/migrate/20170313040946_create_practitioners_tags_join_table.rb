class CreatePractitionersTagsJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :practitioners_tags do |t|
      t.integer :practitioner_id, null: false
      t.integer :tag_id, null: false

      t.index :practitioner_id
      t.index :tag_id
    end
  end
end
