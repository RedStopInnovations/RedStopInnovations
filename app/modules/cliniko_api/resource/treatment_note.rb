module ClinikoApi
  module Resource
    class TreatmentNote < Base
      class Answer
        include Virtus.model
        attribute :value, String
        attribute :selected, Boolean
      end

      class Question
        include Virtus.model
        attribute :name, String
        attribute :type, String # text, paragraph, checkboxes, radiobuttons
        attribute :answer, String
        attribute :answers, Array[Answer] # if type is radiobuttons or checkboxes
      end

      class Section
        include Virtus.model
        attribute :name, String
        attribute :questions, Array[Question]
      end

      class Content
        include Virtus.model
        attribute :sections, Array[Section]
      end

      attribute :id, String
      attribute :title, String
      attribute :draft, Boolean
      attribute :author_name, String
      attribute :content, Content

      attribute :deleted_at, DateTime
      attribute :created_at, DateTime
      attribute :updated_at, DateTime
      attribute :practitioner, Hash
      attribute :patient, Hash
      attribute :treatment_note_template, Hash

      def parse_patient_id
        patient['links']['self'].split('/').last
      end

      def parse_treatment_note_template_id
        if treatment_note_template.present?
          treatment_note_template['links']['self'].split('/').last
        end
      end
    end
  end
end
