module Report
    module Cases
      class All
        class Options
            attr_accessor :start_date,
                          :end_date,
                          :practitioner_ids,
                          :case_type_ids,
                          :status,
                          :page

            def initialize(options = {})
              @start_date = options[:start_date]
              @end_date = options[:end_date]
              @status = options[:status]
              @practitioner_ids = options[:practitioner_ids]
              @page = options[:page]
            end

            def to_params
              params = {}

              if status.present?
                params[:status] = status
              end

              if start_date.present?
                params[:start_date] = start_date.strftime('%Y-%m-%d')
              end

              if end_date.present?
                params[:end_date] = end_date.strftime('%Y-%m-%d')
              end

              params[:practitioner_ids] = practitioner_ids if practitioner_ids.present?

              params[:case_type_ids] = case_type_ids if case_type_ids.present?

              params
            end
        end

        attr_reader :business, :result, :options

        def self.make(business, options)
          new(business, options)
        end

        def initialize(business, options)
          @business = business
          @options = options
          calculate
        end

        def as_csv
          CSV.generate(headers: true) do |csv|
            csv << ["Case", "Case Id", "Practitioner", "Practitioner Id", "Client", "Client Id", "Invoice total", "End date", "Created", "State"]

            records = patient_cases_query.preload(:patient, :case_type, :practitioner, :invoices).to_a

            records.each do |patient_case|
              invoiced_amount_total = patient_case.invoices.to_a.sum(&:amount)
              csv << [
                patient_case.case_type.title,
                patient_case.case_type.id,
                patient_case.practitioner&.full_name,
                patient_case.practitioner&.id,
                patient_case.patient.full_name,
                patient_case.patient.id,
                invoiced_amount_total.round(2).to_s,
                patient_case.end_date&.strftime('%b %d, %Y'),
                patient_case.created_at.strftime('%b %d, %Y'),
                patient_case.patient.state
              ]
            end
          end
        end

        private

        def calculate
          @result = {}

          @result[:paginated_patient_cases] = patient_cases_query.
                  preload(:patient, :case_type, :practitioner, :invoices).
                  page(options.page)
        end

        def patient_cases_query
          query = business.patient_cases.not_archived

          if options.status.present?
            query = query.where('patient_cases.status = ?', options.status)
          end

          if options.start_date
            query = query.where('patient_cases.created_at >= ?', options.start_date.beginning_of_day)
          end

          if options.end_date
            query = query.where('patient_cases.created_at <= ?', options.end_date.end_of_day)
          end

          if options.practitioner_ids.present?
            query = query.where('patient_cases.practitioner_id' => options.practitioner_ids)
          end

          if options.case_type_ids.present?
            query = query.where('patient_cases.case_type_id' => options.case_type_ids)
          end

          query = query.order('patient_cases.created_at' => :desc)

          query
        end
      end
    end
  end
