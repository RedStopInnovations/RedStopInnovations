# == Schema Information
#
# Table name: courses
#
#  id                     :integer          not null, primary key
#  title                  :string
#  video_url              :text
#  presenter_full_name    :string
#  course_duration        :string
#  cpd_points             :string
#  description            :text
#  reflection_answer      :text
#  profession_tags        :text
#  seo_page_title         :string
#  seo_description        :text
#  seo_metatags           :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  thumbnail_file_name    :string
#  thumbnail_content_type :string
#  thumbnail_file_size    :integer
#  thumbnail_updated_at   :datetime
#

class Course < ApplicationRecord
  serialize :profession_tags, type: Array

  has_attached_file :thumbnail,
                    styles: {
                      medium: "300x300>",
                      thumb: "100x100#"
                    }

  validates :title,
            presence: true,
            length: { maximum: 255 }

  validates :video_url,
            presence: true

  validates :presenter_full_name,
            presence: true,
            length: { maximum: 150 }

  validates :course_duration, :cpd_points, :description, :reflection_answer,
            presence: true

  validates_attachment_content_type :thumbnail, content_type: /\Aimage\/.*\z/
end
