# == Schema Information
#
# Table name: seopages
#
#  id               :integer          not null, primary key
#  service_id       :integer          not null
#  page_title       :string           not null
#  page_description :string           not null
#  content          :text             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  professtion_id   :integer
#  city_id          :integer
#  meta_tags        :string
#  h1               :string
#  h3_one           :string
#  h3_two           :string
#  breadcrumb       :string
#
# Indexes
#
#  index_seopages_on_city_id         (city_id)
#  index_seopages_on_professtion_id  (professtion_id)
#  index_seopages_on_service_id      (service_id)
#

class Seopage < ApplicationRecord
  belongs_to :professtion_tag, class_name: 'Tag', foreign_key: :professtion_id
  belongs_to :city_tag, class_name: 'Tag', foreign_key: :city_id
  belongs_to :service_tag, class_name: 'Tag', foreign_key: :service_id

  validates_presence_of :professtion_id, :service_id, :city_id
  validates_presence_of :page_title, :h1

  validates_length_of :page_title, :h1, :h3_one, :h3_two, :breadcrumb,
                      maximum: 200,
                      allow_nil: true,
                      allow_blank: true

  def friendly_url
    '/' << [
      professtion_tag.try(:slug),
      service_tag.try(:slug),
      city_tag.try(:slug),
    ].join('/')
  end
end
