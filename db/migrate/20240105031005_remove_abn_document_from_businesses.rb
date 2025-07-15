class RemoveAbnDocumentFromBusinesses < ActiveRecord::Migration[7.0]
  def change
    remove_column :businesses, :abn_document, :string
  end
end
