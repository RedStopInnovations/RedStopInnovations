# == Schema Information
#
# Table name: deleted_resources
#
#  id                    :integer          not null, primary key
#  business_id           :integer          not null
#  resource_id           :integer          not null
#  resource_type         :string           not null
#  author_id             :integer
#  author_type           :string
#  deleted_at            :datetime         not null
#  associated_patient_id :integer
#
# Indexes
#
#  index_deleted_resources_on_business_id  (business_id)
#

class DeletedResource < ApplicationRecord
  belongs_to :resource, -> { unscope(where: :deleted_at) }, polymorphic: true
  belongs_to :author, polymorphic: true
  belongs_to :business

  belongs_to :associated_patient, -> { with_deleted }, class_name: 'Patient', optional: true
end
