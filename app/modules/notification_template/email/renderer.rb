module NotificationTemplate
  module Email
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
        body_template = template.body.dup
        subject_template = template.subject.dup

        variables = build_variables
        # Replace variables
        build_variables.each do |key, val|
          if val.present?
            santizied_val = val.to_s
          end

          body_template.gsub! %r/{{\s*#{Regexp.quote(key)}\s*}}/ do |match|
            santizied_val
          end

          subject_template.gsub! %r/{{\s*#{Regexp.quote(key)}\s*}}/ do |match|
            santizied_val
          end
        end

        # Sanitize html
        renderred_body = ::ActionController::Base.helpers.sanitize(
          body_template,
          scrubber: NotificationTemplate::Email::HtmlScrubber.new
        )

        # @TODO: sanitize subject?
        renderred_subject = subject_template

        NotificationTemplate::Email::RenderResult.new(renderred_subject, renderred_body)
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
