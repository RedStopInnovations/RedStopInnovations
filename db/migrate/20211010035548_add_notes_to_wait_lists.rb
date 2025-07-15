class AddNotesToWaitLists < ActiveRecord::Migration[5.2]
  def change
    add_column :wait_lists, :notes, :text
  end
end
