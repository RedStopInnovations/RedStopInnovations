# == Schema Information
#
# Table name: cpd_certificates
#
#  id                :integer          not null, primary key
#  course_id         :integer
#  course_title      :string
#  first_name        :string           not null
#  last_name         :string           not null
#  profession        :string           not null
#  email             :string           not null
#  course_duration   :string           not null
#  course_reflection :text
#  cpd_points        :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_cpd_certificates_on_course_id  (course_id)
#  index_cpd_certificates_on_email      (email)
#

class CpdCertificate < ApplicationRecord

  validates :first_name, :last_name,
            presence: true,
            length: { maximum: 35 }

  validates :email,
            email: true,
            length: { maximum: 100 }

  validates :profession,
            inclusion: { in: Practitioner::PROFESSIONS }
  validates :course_reflection,
            presence: true,
            length: { maximum: 1000 }

  validates_presence_of :course_duration, :cpd_points

  class << self
    def initialize_from_course(course)
      new(
        course_duration: course.course_duration,
        course_reflection: course.reflection_answer,
        cpd_points: course.cpd_points,
        course_title: course.title,
        course_id: course.id
      )
    end
  end
end
