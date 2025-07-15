# == Schema Information
#
# Table name: api_keys
#
#  id              :integer          not null, primary key
#  user_id         :integer          not null
#  token           :string           not null
#  active          :boolean          default(FALSE)
#  created_at      :datetime         not null
#  last_used_at    :datetime
#  last_used_by_ip :string
#
# Indexes
#
#  index_api_keys_on_token    (token) UNIQUE
#  index_api_keys_on_user_id  (user_id)
#

class ApiKey < ApplicationRecord
  belongs_to :user

  validates_presence_of :user, :token

  scope :active, -> { where(active: true) }

  def self.generate_token
    begin
      token = SecureRandom::hex(16)
    end while exists?(token: token)
    token
  end

  def deactivate!
    update_attribute :active, false
  end
end
