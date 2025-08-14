module Trigger
  class TriggerWordCalculator
    def call(trigger_word)
      business = trigger_word.category.business
      query = business.treatment_notes.search_all_words(trigger_word.text)

      mentions_count = query.count
      patients_count = query.select('DISTINCT patient_id').count

      Trigger::Report.new(
        mentions_count,
        patients_count
      )
    end
  end
end
