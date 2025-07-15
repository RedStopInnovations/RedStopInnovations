module Report
  module Cases
    class InvoiceTotalPerCase
      attr_reader :business, :results, :options, :practitioners

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        parse_options
        calculate
      end

      def as_chart_data
        data = {}
        data[:labels] = results.map { |e| e[:date].strftime('%b') }
        data[:datasets] = [
          {
            label: "Total",
            backgroundColor: 'rgba(68, 182, 84, 0.35)',
            borderColorColor: 'rgb(68, 182, 84)',
            pointBackgroundColor: 'rgb(68, 182, 84)',
            pointBorderColor: 'rgb(68, 182, 84)',
            data: results.map { |e| e[:cases_count] }
          }
        ]
        data
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["Practitioner", "Invoice Average", "Client Cases"]

          @practitioners.each do |index, row|
            csv << [
              row[:name],
              row[:average].to_f.round(2).to_s,
              row[:count]
            ]
          end
        end
      end

      def calculate
        @results = []
        @practitioners = {}

        groups_by_month =
          patients_query.pluck(:updated_at, :amount, :practitioner_id, :full_name).group_by do |record|
            record[0].beginning_of_month.to_date
          end

        tmp_date = Date.parse(@options[:start_date]).beginning_of_month rescue 11.months.ago.beginning_of_month.to_date
        end_date = Date.parse(@options[:end_date]) rescue Time.zone.now

        begin
          total_amount = 0

          if groups_by_month[tmp_date]
            total_amount =
              groups_by_month[tmp_date].inject(0) { |sum, e| sum + e[1] }
            groups_by_month[tmp_date].each do |row|
              @practitioners[row[2]] = {average: 0, total: 0, count: 0, name: row[3]} unless @practitioners[row[2]]
              @practitioners[row[2]][:total] += row[1]
              @practitioners[row[2]][:count] += 1
            end
          end

          @results << {
            date: tmp_date,
            cases_count: total_amount / (groups_by_month[tmp_date].try(:count) || 1),
          }
          tmp_date = tmp_date.next_month
        end while tmp_date <= end_date

        # Cacuated Average Invoice For Practitioners
        @practitioners.each do |index, row|
          row[:average] = row[:total] / (row[:count].nonzero? || 1)
        end

      end

      def patients_query
        query = business.patient_cases.where(status: PatientCase::STATUS_DISCHARGED)
                                      .includes(:practitioner)
                                      .joins(:invoices)
                                      .where("invoices.issue_date >= ?", options[:start_date])
                                      .where("invoices.issue_date <= ?", options[:end_date])

        query = query.where(case_type_id: @options[:case_type_ids]) if @options[:case_type_ids].present?
        query = query.where(practitioner_id: @options[:practitioner_ids]) if @options[:practitioner_ids].present?
        query
      end

      private
      def parse_options
        options[:start_date] = options[:start_date].try(:to_date) || 11.months.ago.beginning_of_month
        options[:end_date] = options[:end_date].try(:to_date) || Date.current
      end
    end
  end
end
