# == Schema Information
#
# Table name: incoming_messages
#
#  id          :integer          not null, primary key
#  patient_id  :integer
#  message     :text
#  received_at :datetime
#  sender      :string
#  receiver    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class IncomingMessage < ApplicationRecord
  belongs_to :patient, -> { with_deleted }

  validates_presence_of :message, :patient_id
end
