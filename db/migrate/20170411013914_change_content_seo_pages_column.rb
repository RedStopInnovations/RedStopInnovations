class ChangeContentSeoPagesColumn < ActiveRecord::Migration[5.0]
  def self.up
    change_column :seopages, :content, :text
  end

  def self.down
    change_column :seopages, :content, :string
  end
end
