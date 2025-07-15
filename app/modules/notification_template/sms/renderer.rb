module NotificationTemplate
  module Sms
    class Renderer
      attr_reader :template, :embeddable_resources

      # @param template Template
      # @param embeddable_resources Array[ActiveRecord]
      def initialize(template, embeddable_resources = [])
        @template = template
        @embeddable_resources = embeddable_resources
      end

      # Replace variables surrounded by "{{" and "}}" with given values. Allow spaces after "{{" and before "}}".
      def render(options = {})
        content_template = template.content.dup

        variables = build_variables
        # Replace variables
        build_variables.each do |key, val|
          if val.present?
            santizied_val = val.to_s
          end

          content_template.gsub! %r/{{\s*#{Regexp.quote(key)}\s*}}/ do |match|
            santizied_val
          end
        end

        # @TODO: sanitize text?
        renderred_content = content_template

        RenderResult.new(renderred_content)
      end

      private

      def build_variables
        embeddable_resources.map do |model|
          NotificationTemplate::Embeddable::Factory.make(model).attributes
        end
        .reduce({}, :merge)
        .merge(general_attributes)
      end

      def general_attributes
        NotificationTemplate::Embeddable::General.new.attributes
      end
    end
  end
end
