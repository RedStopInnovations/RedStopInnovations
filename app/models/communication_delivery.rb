# == Schema Information
#
# Table name: communication_delivery
#
#  id                       :bigint           not null, primary key
#  communication_id         :integer          not null
#  recipient                :string
#  status                   :string
#  error_type               :string
#  error_message            :string
#  tracking_id              :string           not null
#  last_tried_at            :datetime
#  provider_id              :string           not null
#  provider_resource_id     :string
#  provider_delivery_status :string
#  provider_metadata        :json
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_communication_delivery_on_communication_id  (communication_id)
#
class CommunicationDelivery < ApplicationRecord
  include RansackAuthorization::CommunicationDelivery

  self.table_name = 'communication_delivery'

  PROVIDER_ID_SENDGRID = 'sendgrid'
  PROVIDER_ID_TWILIO   = 'twilio'

  STATUS_SCHEDULED = 'scheduled' # Initial status of any message. Scheduled to be sent in background.
  STATUS_PROCESSED = 'processed' # After the message request has been accepted by the service provider.
  STATUS_ERROR     = 'error'     # Any case that cause the message can't be sent.
  STATUS_DELIVERED = 'delivered' # Message has been confirmed successfully delivered to the recipient

  DELIVERY_ERROR_TYPE_INTERNAL_ERROR = 'internal_error' # Internal server error
  DELIVERY_ERROR_TYPE_SERVICE_ERROR = 'service_error' # Service provider error(5xx api response). Account suspended/blocked. Rate limit.
  DELIVERY_ERROR_TYPE_INVALID_RECIPIENT = 'invalid_recipient' # Invalid recipient email/mobile
  DELIVERY_ERROR_TYPE_UNREACHABLE = 'unreachable' # Bounced, Dropped, Blocked
  DELIVERY_ERROR_TYPE_UNKNOWN = 'unknown'

  belongs_to :communication

  def status_error?
    status == STATUS_ERROR
  end
end
