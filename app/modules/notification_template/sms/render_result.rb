module NotificationTemplate
  module Sms
    class RenderResult
      attr_reader :content

      def initialize(content)
        @content = content
      end
    end
  end
end
