module Webhook
  module TreatmentNote
    class Serializer

      attr_reader :treatment

      def initialize(treatment)
        @treatment = treatment
      end

      def as_json(options = {})
        attrs = treatment.attributes.symbolize_keys.slice(
          :id,
          :name,
          :status,
          :sections,
          :updated_at,
          :created_at
        )

        attrs[:template] = treatment.treatment_note_template&.name
        attrs[:case] = treatment.patient_case&.case_type&.title

        if treatment.appointment.present?
          attrs[:appointment] =
            Webhook::Appointment::Serializer.new(treatment.appointment).as_json({relations: false})
        end

        attrs[:patient] = Webhook::Patient::Serializer.new(treatment.patient).as_json
        attrs
      end
    end
  end
end