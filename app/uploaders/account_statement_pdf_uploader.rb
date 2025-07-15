class AccountStatementPdfUploader < ApplicationUploader
  def store_dir
    "uploads/account_statements/#{model.id}"
  end
end
