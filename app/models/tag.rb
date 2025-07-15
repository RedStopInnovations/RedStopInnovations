# == Schema Information
#
# Table name: tags
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  slug           :string           not null
#  classification :string
#
# Indexes
#
#  index_tags_on_classification  (classification)
#  index_tags_on_slug            (slug) UNIQUE
#

class Tag < ApplicationRecord
  has_and_belongs_to_many :posts
  has_and_belongs_to_many :practitioners

  enum classification: {
    profession: 'profession',
    city: 'city',
    service: 'service',
    clinic: 'clinic'
  }

  validates :name,
            presence: true,
            length: { minimum: 2, maximum: 25 }, # TODO: Im not sure
            uniqueness: { case_sensitive: false }

  before_save :generate_slug, if: :name_changed?

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
