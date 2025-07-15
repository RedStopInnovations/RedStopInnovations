class CreateAccountStatementItems < ActiveRecord::Migration[5.0]
  def change
    create_table :account_statement_items do |t|
      t.integer :account_statement_id, null: false, index: true
      t.integer :source_id, null: false
      t.string :source_type, null: false
    end
  end
end
