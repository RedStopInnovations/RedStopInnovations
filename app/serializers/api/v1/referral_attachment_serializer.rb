module Api
  module V1
    class ReferralAttachmentSerializer < BaseSerializer
      type 'referral_attachments'

      attributes :created_at

      attribute :attachment do
        {
          file_name: @object.attachment_file_name,
          file_size: @object.attachment_file_size,
          content_type: @object.attachment_content_type
        }
      end

      link :self do
        @url_helpers.api_v1_referral_attachment_url(referral_id: @object.referral_id, id: @object.id)
      end
    end
  end
end
