# == Schema Information
#
# Table name: stripe_infos
#
#  id                 :integer          not null, primary key
#  stripe_customer_id :string
#  patient_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class StripeInfo < ApplicationRecord
	belongs_to :patient, -> { with_deleted }
end
