class AddAbnToBusinesses < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :abn, :string
    add_column :businesses, :abn_document, :string
  end
end
