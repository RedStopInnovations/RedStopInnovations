class AddCustomPageContentsToSeopage < ActiveRecord::Migration[5.0]
  def change
      remove_column :seopages, :professtion
      remove_column :seopages, :city

      add_reference :seopages, :professtion
      add_reference :seopages, :city

      add_column :seopages, :meta_tags, :string
      add_column :seopages, :h1 , :string
      add_column :seopages, :h3_one, :string
      add_column :seopages, :h3_two, :string
      add_column :seopages, :breadcrumb, :string
  end
end
