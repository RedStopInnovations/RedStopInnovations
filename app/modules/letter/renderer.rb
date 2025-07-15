module Letter
  class Renderer
    MISSING_HIGHLIGHT_COLOR = '#fb4a47'
    attr_reader :patient, :template
    # @param patient Patient
    # @param letter_template LetterTemplate
    def initialize(patient, letter_template)
      @patient = patient
      @template = letter_template
    end

    # @param extra_models Array array of ActiveRecord objects
    # Replace variables surrounded by "{{" and "}}" with given values.
    # This allow spaces after "{{" and before "}}".
    def render(extra_models = [], options = {})
      missing_variables = []
      content = @template.content.dup
      hightlight_missing = options[:hightlight_missing]

      build_variables(extra_models).each do |key, val|
        if val.present?
          santizied_val = val.to_s
        else
          if hightlight_missing
            # Highlight missing variables
            santizied_val = hightlight_missing_variable(key)
          end
        end
        content.gsub! %r/{{\s*#{Regexp.quote(key)}\s*}}/ do |match|
          # Only hightlight and report missing for recognizable variables
          unless val.present?
            missing_variables << key
          end
          santizied_val
        end
      end

      rendered_content = ActionController::Base.helpers.sanitize(
        content,
        scrubber: Letter::Scrubber.new
      )

      RenderResult.new(rendered_content, missing_variables)
    end

    private

    def build_variables(extra_models = [])
      models = [patient] + extra_models

      models.map do |model|
        Letter::Embeddable::Factory.make(model).attributes
      end.reduce({}, :merge).
         merge(general_attributes).
         merge(patient_contact_attributes)
    end

    def general_attributes
      Letter::Embeddable::General.new.attributes
    end

    def patient_contact_attributes
      contacts = []

      patient.primary_doctor_contact.tap do |contact|
        contacts << Letter::Embeddable::DoctorContact.new(contact || OpenStruct.new)
      end

      patient.primary_specialist_contact.tap do |contact|
        contacts << Letter::Embeddable::SpecialistContact.new(contact || OpenStruct.new)
      end

      patient.primary_referrer_contact.tap do |contact|
        contacts << Letter::Embeddable::ReferrerContact.new(contact || OpenStruct.new)
      end

      patient.primary_invoice_to_contact.tap do |contact|
        contacts << Letter::Embeddable::InvoiceToContact.new(contact || OpenStruct.new)
      end

      patient.primary_other_contact.tap do |contact|
        contacts << Letter::Embeddable::OtherContact.new(contact || OpenStruct.new)
      end

      contacts.map(&:attributes).reduce({}, :merge)
    end

    def hightlight_missing_variable(key)
      "<span style=\"background-color: #{MISSING_HIGHLIGHT_COLOR}\">{{#{ key }}}</span>"
    end
  end
end
