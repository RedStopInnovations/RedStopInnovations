# == Schema Information
#
# Table name: conversation_messages
#
#  id                      :integer          not null, primary key
#  conversation_room_id    :integer
#  content                 :text
#  conversation_message_id :integer
#  user_id                 :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_conversation_messages_on_conversation_message_id  (conversation_message_id)
#  index_conversation_messages_on_conversation_room_id     (conversation_room_id)
#  index_conversation_messages_on_user_id                  (user_id)
#

class ConversationMessage < ApplicationRecord
  belongs_to :room, class_name: "ConversationRoom"
  belongs_to :user
  has_many :replies, class_name: "ConversationMessage"

  validates_presence_of :user, :content
end
