class CreateAccountStatements < ActiveRecord::Migration[5.0]
  def change
    create_table :account_statements do |t|
      t.integer :business_id, null: false, index: true
      t.integer :source_id, null: false
      t.string :source_type, null: false
      t.string :public_token, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.jsonb :options, default: {} # optional params, e.g. patient_id, invoice_status
      t.string :number, null: false
      t.datetime :deleted_at
      t.string :pdf

      t.timestamps
      t.index [:source_id, :source_type]
    end

    add_index :account_statements,
              :business_id,
              where: "deleted_at IS NULL",
              name: 'account_statements_business_id_not_deleted_idx'
  end
end
