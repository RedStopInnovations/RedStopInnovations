class AddInsuranceDocumentToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :insurance_document, :string
  end
end
