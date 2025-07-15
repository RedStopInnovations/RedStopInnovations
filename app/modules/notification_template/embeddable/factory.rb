module NotificationTemplate
  module Embeddable
    class Factory
      def self.make(model)
        case model
        when ::Patient
          NotificationTemplate::Embeddable::Patient.new(model)
        when ::Practitioner
          NotificationTemplate::Embeddable::Practitioner.new(model)
        when ::Business
          NotificationTemplate::Embeddable::Business.new(model)
        when ::Appointment
          NotificationTemplate::Embeddable::Appointment.new(model)
        else
          raise "Unknown factory for `#{model.class.name}`"
        end
      end
    end
  end
end
