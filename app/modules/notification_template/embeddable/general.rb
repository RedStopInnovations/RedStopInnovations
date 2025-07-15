module NotificationTemplate
  module Embeddable
    class General < Base
      VARIABLES = [
        'General.CurrentDate'
      ]

      def initialize
        super build_attributes
      end

      private

      def build_attributes
        {
          'General.CurrentDate' => Time.zone.today.strftime('%d %B %Y')
        }
      end
    end
  end
end
