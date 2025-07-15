# == Schema Information
#
# Table name: medipass_quotes
#
#  id              :integer          not null, primary key
#  invoice_id      :integer          not null
#  transaction_id  :string           not null
#  member_id       :string           not null
#  amount_gap      :decimal(10, 2)   default(0.0)
#  amount_benefit  :decimal(10, 2)   default(0.0)
#  amount_fee      :decimal(10, 2)   default(0.0)
#  amount_charged  :decimal(10, 2)   default(0.0)
#  amount_discount :decimal(10, 2)   default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_medipass_quotes_on_invoice_id  (invoice_id)
#

class MedipassQuote < ApplicationRecord
  belongs_to :invoice
end
