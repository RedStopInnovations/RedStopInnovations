module NotificationTemplate
  module Email
    class Template
      attr_reader :subject, :body

      def initialize(subject, body)
        @subject = subject
        @body = body
      end
    end
  end
end