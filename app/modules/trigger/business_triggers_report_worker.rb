module Trigger
  class BusinessTriggersReportWorker < ::ApplicationJob
    def perform(business_id)
      business = Business.find business_id
      business.trigger_words.find_each do |word|
        begin
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
        rescue => e
          Sentry.capture_exception(e)
        end
      end

      business.trigger_categories.find_each do |cat|
        begin
          report = TriggerCategoryCalculator.new.call(cat)

          trigger_report = cat.trigger_report
          if trigger_report.nil?
            trigger_report = TriggerReport.new(
              trigger_source: cat
            )
          end

          trigger_report.assign_attributes(
            mentions_count: report.mentions_count,
            patients_count: report.patients_count
          )

          trigger_report.save!
        rescue => e
          Sentry.capture_exception(e)
        end
      end
    end
  end
end
