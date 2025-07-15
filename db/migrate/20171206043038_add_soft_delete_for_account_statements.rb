class AddSoftDeleteForAccountStatements < ActiveRecord::Migration[5.0]
  def change
    add_column :patient_statements, :deleted_at, :datetime
    add_column :contact_statements, :deleted_at, :datetime
  end
end
