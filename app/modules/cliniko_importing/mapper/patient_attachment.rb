module ClinikoImporting
  module Mapper
    module PatientAttachment
      # @param cliniko_patient_attachment ClinikoApi::Resource::PatientAttachment
      def self.build(cliniko_patient_attachment)
        local_attrs = {}
        {
          filename: :attachment_file_name,
          content_type: :attachment_content_type,
          size: :attachment_file_size,
          description: :description,
          created_at: :created_at,
          updated_at: :updated_at
        }.each do |cliniko_field, local_field|
          local_attrs[local_field] = cliniko_patient_attachment.send cliniko_field
        end

        local_attrs
      end

    end
  end
end
