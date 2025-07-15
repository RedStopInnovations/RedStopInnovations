module Letter
  module Embeddable
    class Factory
      def self.make(model)
        case model
        when ::Patient
          Letter::Embeddable::Patient.new(model)
        when ::Practitioner
          Letter::Embeddable::Practitioner.new(model)
        when ::Business
          Letter::Embeddable::Business.new(model)
        when ::Appointment
          Letter::Embeddable::Appointment.new(model)
        when ::Invoice
          Letter::Embeddable::Invoice.new(model)
        else
          raise "Unknown factory for `#{model.class.name}`"
        end
      end
    end
  end
end
