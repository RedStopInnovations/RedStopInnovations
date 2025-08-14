class TreatmentNoteTemplate < ApplicationRecord
  include DeletionRecordable

  belongs_to :business

  scope :not_deleted, -> { where(deleted_at: nil) }
end