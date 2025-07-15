module ClinikoApi
  module Resource
    class TreatmentTemplate < Base
      class Answer
        include Virtus.model
        attribute :value, String
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

      class PrintSettings
        include Virtus.model
        attribute :include_patient_address, Boolean, default: false
        attribute :include_patient_dob, Boolean, default: false
        attribute :include_patient_medicare, Boolean, default: false
        attribute :include_patient_occupation, Boolean, default: false
        attribute :include_patient_reference_number, Boolean, default: false
        attribute :title, String
      end

      attribute :id, String
      attribute :name, String
      attribute :content, Content

      attribute :created_at, DateTime
      attribute :updated_at, DateTime
      attribute :deleted_at, DateTime
      attribute :print_settings, PrintSettings
    end
  end
end
