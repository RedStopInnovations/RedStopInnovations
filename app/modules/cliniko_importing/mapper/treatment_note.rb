module ClinikoImporting
  module Mapper
    module TreatmentNote
      # @param cliniko_patient ClinikoApi::Resource::TreatmentNote
      def self.build(cliniko_treatment_note)
        local_attrs = {}
        {
          title: :name,
          author_name: :author_name,
          created_at: :created_at,
          updated_at: :updated_at
        }.each do |cliniko_field, local_field|
          local_attrs[local_field] = cliniko_treatment_note.send cliniko_field
        end

        if cliniko_treatment_note.draft
          local_attrs[:status] = 'Draft'
        else
          local_attrs[:status] = 'Final'
        end

        local_sections = []

        if cliniko_treatment_note.content && cliniko_treatment_note.content.sections.present?
          cliniko_treatment_note.content.sections.each do |cliniko_section|
            local_section = {
              name: cliniko_section.name,
              questions: []
            }

            cliniko_section.questions.each do |cliniko_question|
              local_question = {
                name: cliniko_question.name
              }
              local_question[:type] = {
                'text'         => 'Text',
                'paragraph'    => 'Paragraph',
                'checkboxes'   => 'Checkboxes',
                'radiobuttons' => 'Radiobuttons'
              }[cliniko_question.type]
              next if local_question[:type].nil?

              if cliniko_question.type == 'text' || cliniko_question.type == 'paragraph'
                local_question[:answer] = {
                  content: santizie_answer_content(cliniko_question.answer)
                }
              elsif cliniko_question.type == 'checkboxes' || cliniko_question.type == 'radiobuttons'
                local_question[:answers] = []

                cliniko_question.answers.each do |cliniko_answer|
                  local_answer = {}
                  local_answer[:content] = santizie_answer_content(cliniko_answer.value)
                  if cliniko_answer.selected
                    local_answer[:selected] = '1'
                  end

                  local_question[:answers] << local_answer
                end
              end

              local_section[:questions] << local_question
            end

            local_sections << local_section
          end
        end

        local_attrs[:sections] = local_sections

        local_attrs
      end

      def self.santizie_answer_content(content)
        if content.nil?
          nil
        else
          content.
            gsub('<div>', '').
            gsub('</div>', "\n").
            gsub('<br>', "\n").
            gsub('<br />', "\n").
            gsub('<br/>', "\n").
            strip
        end
      end
    end
  end
end
