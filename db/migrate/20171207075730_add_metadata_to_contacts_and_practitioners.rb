class AddMetadataToContactsAndPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :metadata, :jsonb, default: {}
    add_column :practitioners, :metadata, :jsonb, default: {}
  end
end
