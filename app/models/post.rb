# == Schema Information
#
# Table name: posts
#
#  id                     :integer          not null, primary key
#  practitioner_id        :integer          not null
#  title                  :string           not null
#  slug                   :string           not null
#  meta_description       :text
#  meta_keywords          :text
#  summary                :text
#  content                :text
#  published              :boolean          default(FALSE), not null
#  thumbnail_file_name    :string
#  thumbnail_content_type :string
#  thumbnail_file_size    :integer
#  thumbnail_updated_at   :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_posts_on_practitioner_id                (practitioner_id)
#  index_posts_on_practitioner_id_and_published  (practitioner_id,published)
#  index_posts_on_published                      (published)
#  index_posts_on_slug                           (slug) UNIQUE
#

class Post < ApplicationRecord
  has_attached_file :thumbnail,
                    styles: {
                      thumb:  "100x100>",
                      medium: "400x400>"
                    },
                    convert_options: {
                      thumb: "-quality 75 -strip",
                      medium: "-quality 75 -strip"
                    },
                    s3_headers: {
                      'Cache-Control' => 'max-age=2592000',
                      'Expires' => 30.days.from_now.httpdate
                    }

  belongs_to :practitioner, inverse_of: :posts
  has_and_belongs_to_many :tags

  validates :title,
            presence: true,
            length: { minimum: 5, maximum: 200 },
            uniqueness: { case_sensitive: false }
  validates :summary,
            presence: true,
            length: { maximum: 1000 }
  validates_presence_of :thumbnail, :content
  validates_length_of :content, maximum: 1000000, message: 'too much words'
  validates_length_of :meta_description, :meta_keywords, maximum: 255
  validates_attachment_content_type :thumbnail, content_type: /\Aimage\/.*\z/

  before_save :generate_slug, if: :title_changed?

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  def self.ransackable_attributes(auth_object = nil)
    ['title']
  end

  private

  def generate_slug
    self.slug = title.parameterize
  end
end
