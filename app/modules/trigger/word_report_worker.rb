module Trigger
  class WordReportWorker < ::ApplicationJob
    def perform(word_id)
      word = TriggerWord.find(word_id)
      report = TriggerWordCalculator.new.call(word)

      trigger_report = word.trigger_report
      if trigger_report.nil?
        trigger_report = TriggerReport.new(
          trigger_source: word
        )
      end

      trigger_report.assign_attributes(
        mentions_count: report.mentions_count,
        patients_count: report.patients_count
      )

      trigger_report.save!
    end
  end
end
