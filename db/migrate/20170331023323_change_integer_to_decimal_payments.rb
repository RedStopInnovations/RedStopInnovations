class ChangeIntegerToDecimalPayments < ActiveRecord::Migration[5.0]
  def self.up
    change_table :payments do |t|
      t.change :eftpos, :decimal, precision: 10, scale: 2, default: 0
      t.change :hicaps, :decimal, precision: 10, scale: 2, default: 0
      t.change :cash, :decimal, precision: 10, scale: 2, default: 0
      t.change :medicare, :decimal, precision: 10, scale: 2, default: 0
      t.change :workcover, :decimal, precision: 10, scale: 2, default: 0
      t.change :dva, :decimal, precision: 10, scale: 2, default: 0
      t.change :other, :decimal, precision: 10, scale: 2, default: 0
      t.change :amount, :decimal, precision: 10, scale: 2, default: 0
    end
  end

  def self.down
    change_table :payments do |t|
      t.change :eftpos, :integer
      t.change :hicaps, :integer
      t.change :cash, :integer
      t.change :medicare, :integer
      t.change :workcover, :integer
      t.change :dva, :integer
      t.change :other, :integer
      t.change :amount, :integer
    end
  end
end
