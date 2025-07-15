class AddIsPartnerToBusiness < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :is_partner, :boolean, default: :false

    add_index :businesses, :is_partner
  end
end
