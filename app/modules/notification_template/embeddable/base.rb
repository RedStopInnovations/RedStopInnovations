module NotificationTemplate
  module Embeddable
    class Base
      attr_accessor :attributes

      def initialize(attributes = {})
        @attributes = attributes
      end

      def [](key)
        attributes[key]
      end
    end
  end
end
