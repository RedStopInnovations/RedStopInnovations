module Api
  module V1
    class PatientAttachmentSerializer < BaseSerializer
      type 'patient_attachments'

      attributes :description,
                 :updated_at,
                 :created_at

      attribute :attachment do
        {
          file_name: @object.attachment_file_name,
          file_size: @object.attachment_file_size,
          content_type: @object.attachment_content_type
        }
      end

      link :self do
        @url_helpers.api_v1_patient_attachment_url(patient_id: @object.patient_id, id: @object.id)
      end
    end
  end
end
