module NotificationTemplate
  module Sms
    class Template
      attr_reader :content

      def initialize(content)
        @content = content
      end
    end
  end
end