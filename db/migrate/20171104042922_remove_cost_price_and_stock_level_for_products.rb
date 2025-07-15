class RemoveCostPriceAndStockLevelForProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :stock_level
    remove_column :products, :cost_price
  end
end
