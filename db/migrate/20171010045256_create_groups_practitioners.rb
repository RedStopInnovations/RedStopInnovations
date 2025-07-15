class CreateGroupsPractitioners < ActiveRecord::Migration[5.0]
  def change
    create_table :groups_practitioners do |t|
      t.integer :group_id
      t.integer :practitioner_id

      t.timestamps

      t.index :group_id
      t.index :practitioner_id
    end
  end
end
