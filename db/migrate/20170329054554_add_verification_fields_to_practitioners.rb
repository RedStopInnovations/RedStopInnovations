class AddVerificationFieldsToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :driver_license, :string
    add_column :practitioners, :ahpra_registration, :string
    add_column :practitioners, :medicare_provider_documentation, :string
    add_column :practitioners, :police_check, :string
    add_column :practitioners, :abn_document, :string
  end
end
