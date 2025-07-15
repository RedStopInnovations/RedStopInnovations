class AddPublicTokenToStatements < ActiveRecord::Migration[5.0]
  def change
    add_column :patient_statements, :public_token, :string
    add_column :contact_statements, :public_token, :string
  end
end