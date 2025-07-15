module Trigger
  class CategoryReportWorker < ::ApplicationJob
    def perform(category_id)
      cat = TriggerCategory.find(category_id)
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
    end
  end
end
