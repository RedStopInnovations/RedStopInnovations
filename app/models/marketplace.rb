# == Schema Information
#
# Table name: marketplaces
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  api_key    :string
#

class Marketplace < ApplicationRecord
  has_many :businesses
  has_many :admin_users

  validates :name,
            presence: true,
            length: { maximum: 100 }

  def generate_api_key!
    begin
      key = "mkt-#{SecureRandom::hex(16)}"
    end while self.class.exists?(api_key: key)

    update_column :api_key, key
  end
end
