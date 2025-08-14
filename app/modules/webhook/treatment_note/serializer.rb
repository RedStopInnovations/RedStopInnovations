module Webhook
  module TreatmentNote
    class Serializer

      attr_reader :treatment_note

      def initialize(treatment_note)
        @treatment_note = treatment_note
      end

      def as_json(options = {})
        attrs = treatment_note.attributes.symbolize_keys.slice(
          :id,
          :name,
          :status,
          :sections,
          :updated_at,
          :created_at
        )

        attrs[:template] = treatment_note.treatment_note_template&.name
        attrs[:case] = treatment_note.patient_case.case_number

        if treatment_note.appointment.present?
          attrs[:appointment] =
            Webhook::Appointment::Serializer.new(treatment_note.appointment).as_json({relations: false})
        end

        attrs[:patient] = Webhook::Patient::Serializer.new(treatment_note.patient).as_json
        attrs
      end
    end
  end
end