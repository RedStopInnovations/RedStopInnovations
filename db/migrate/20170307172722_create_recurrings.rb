class CreateRecurrings < ActiveRecord::Migration[5.0]
  def change
    create_table :recurrings do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.integer :availability_id
      t.integer :recurring, :null => false, :default => 0
    end
  end
end
