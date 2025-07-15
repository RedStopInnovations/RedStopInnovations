# == Schema Information
#
# Table name: conversation_rooms
#
#  id          :integer          not null, primary key
#  business_id :integer
#  url         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ConversationRoom < ApplicationRecord
  has_many :messages, -> { where(conversation_message_id: nil) }, class_name: "ConversationMessage", dependent: :delete_all

  validates :url, presence: true, uniqueness: true
end
