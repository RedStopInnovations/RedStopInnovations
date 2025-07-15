module ClinikoApi
  module Resource
    class PatientAttachment < Base

      attribute :id, String
      attribute :content_type, String
      attribute :description, String
      attribute :filename, String
      attribute :size, String

      attribute :processed_at, DateTime
      attribute :created_at, DateTime
      attribute :updated_at, DateTime
      attribute :archived_at, DateTime
      attribute :deleted_at, DateTime

      attribute :patient, Hash
      attribute :content, Hash
      attribute :user, Hash

      def parse_patient_id
        patient['links']['self'].split('/').last
      end

      def content_url
        content['links']['self']
      end
    end
  end
end
