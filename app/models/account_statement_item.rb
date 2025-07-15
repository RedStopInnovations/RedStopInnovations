# == Schema Information
#
# Table name: account_statement_items
#
#  id                   :integer          not null, primary key
#  account_statement_id :integer          not null
#  source_id            :integer          not null
#  source_type          :string           not null
#
# Indexes
#
#  index_account_statement_items_on_account_statement_id  (account_statement_id)
#

class AccountStatementItem < ApplicationRecord
  belongs_to :account_statement
  belongs_to :source, polymorphic: true
end
