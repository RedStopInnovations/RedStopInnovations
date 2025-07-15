class UploadAttendanceProofForm < BaseForm
  attr_accessor :appointment

  attribute :file, ActionDispatch::Http::UploadedFile

  validates :file,
            file_size: { less_than_or_equal_to: 10.megabytes },
            file_content_type: { allow: ['image/jpeg', 'image/png'] },
            if: Proc.new { |f|
              f.file.present? &&
              f.file.is_a?(ActionDispatch::Http::UploadedFile)
            }

  validate do
    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      errors.add(:base, "File is not valid or empty.")
    end
  end

  validate do
    if appointment.attendance_proofs.count >= App::MAX_ATTENDANCE_PROOFS
      errors.add(:base, "Allow up to #{App::MAX_ATTENDANCE_PROOFS} files per appointment")
    end
  end
end