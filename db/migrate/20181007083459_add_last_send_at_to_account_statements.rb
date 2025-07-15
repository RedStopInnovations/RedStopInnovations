class AddLastSendAtToAccountStatements < ActiveRecord::Migration[5.0]
  def change
    add_column :account_statements, :last_send_at, :datetime
  end
end
