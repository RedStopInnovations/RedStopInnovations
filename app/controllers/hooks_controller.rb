class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def medipass
    MedipassHookHandleService.new.call(params)
    head :ok
  end

  def sendgrid
    # @TODO: add ENV vars to config file
    if ['1', 'true'].include? ENV['SENDGRID_WEBHOOK_SIGNED_ENABLE']
      event_webhook = SendGrid::EventWebhook.new
      is_verified = event_webhook.verify_signature(
        event_webhook.convert_public_key_to_ecdsa(ENV['SENDGRID_WEBHOOK_SIGNED_VERIFICATION_KEY']),
        request.body.read,
        request.env[SendGrid::EventWebhookHeader::SIGNATURE],
        request.env[SendGrid::EventWebhookHeader::TIMESTAMP]
      )

      if is_verified
        # @TODO: create a job
        SendGridEmailDeliveryHookHandleService.new.call(params.to_unsafe_h)
      end
    else
      # @TODO: create a job
      SendGridEmailDeliveryHookHandleService.new.call(params.to_unsafe_h)
    end

    head :ok
  end

  def twilio
    hook_data = params.to_unsafe_h.slice(
      'SmsSid', 'SmsStatus', 'MessageStatus', 'To', 'From',
      'MessagingServiceSid', 'MessageSid', 'AccountSid', 'ApiVersion', 'ErrorCode', 'ErrorMessage'
    )

    TwilioSmsDeliveryHookHandleService.new.call(
      hook_data, params['tracking_id']
    )

    head :ok
  end
end
