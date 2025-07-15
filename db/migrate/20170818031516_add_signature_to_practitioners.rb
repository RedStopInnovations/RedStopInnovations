class AddSignatureToPractitioners < ActiveRecord::Migration[5.0]
  def self.up
    change_table :practitioners do |t|
      t.attachment :signature
    end
  end

  def self.down
    remove_attachment :practitioners, :signature
  end
end
