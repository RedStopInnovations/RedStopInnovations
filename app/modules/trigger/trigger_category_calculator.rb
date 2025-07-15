module Trigger
  class TriggerCategoryCalculator
    def call(trigger_category)
      business = trigger_category.business

      if trigger_category.words.count > 0
        search_phase = trigger_category.words.map do |word|
          word.text.tr(' ', '_')
        end.join(' ')

        query = business.patient_treatments.search_any_word(search_phase)

        mentions_count = query.count
        patients_count = query.select('DISTINCT patient_id').count
      else
        mentions_count = patients_count = 0
      end

      Trigger::Report.new(
        mentions_count,
        patients_count
      )
    end
  end
end
