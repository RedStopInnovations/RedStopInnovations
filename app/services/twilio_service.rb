class TwilioService
  attr_accessor :to_number, :message

  def initialize(options = {})
    @to_number    = options[:to_number]
    @message      = options[:message]
    @from      = options[:from]
  end

  def send_sms
    begin
      params = {
        to:   to_number,
        messaging_service_sid: ENV['TWILIO_SMS_SERVICE_ID'],
        body: message
      }

      if @from.present?
        params[:from] = @from
      end
      client.messages.create params
      return {
        success: true,
        message: "Message sent"
      }
    rescue Twilio::REST::RequestError => e
      Sentry.capture_exception(e)
      return {
        success: false,
        message: e.message
      }
    end
  end

  private

  def client
    Twilio::REST::Client.new
  end
end
