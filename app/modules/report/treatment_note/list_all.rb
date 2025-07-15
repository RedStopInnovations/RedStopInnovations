module Report
  module TreatmentNote
    class ListAll
      class Options
        attr_accessor :practitioner_ids,
                      :template_ids,
                      :start_date,
                      :end_date,
                      :status,
                      :page

        def initialize(options = {})
          @start_date = options[:start_date]
          @end_date = options[:end_date]
          @template_ids = options[:template_ids]
          @practitioner_ids = options[:practitioner_ids]
          @status = options[:status]
          @page = options[:page]
        end

        def to_params
          params = {}

          if start_date
            params[:start_date] = start_date.strftime('%Y-%m-%d')
          end

          if start_date
            params[:end_date] = end_date.strftime('%Y-%m-%d')
          end

          if template_ids.present?
            params[:template_ids] = template_ids
          end

          if practitioner_ids.present?
            params[:practitioner_ids] = practitioner_ids
          end

          if status.present?
            params[:status] = status
          end

          params
        end
      end

      attr_reader :business, :results, :options

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
          csv << [
            "ID", "Author", "Client", "Client ID", "Appointment date", "Template name", "Created date", "Status", "Content"
          ]

          treatment_notes_query.find_each(batch_size: 200) do |treatment|
            appointment = treatment.appointment
            author = treatment.author.present? ? treatment.author.full_name : treatment.author_name
            csv << [
              treatment.id,
              author,
              treatment.patient.try(:full_name),
              treatment.patient&.id,
              appointment.try(:start_time).try(:strftime, "%d %b %Y"),
              treatment.name,
              treatment.created_at.strftime("%d %b %Y"),
              treatment.status == Treatment::STATUS_FINAL ? "FINAL" : "DRAFT",
              treatment.sections
            ]
          end
        end
      end

      private

      def treatment_notes_query
        query = business.patient_treatments.includes(:patient, :author, appointment: [:practitioner])

        if @options.start_date.present? && @options.end_date.present?
          query = query.where(
            created_at: @options.start_date.beginning_of_day..@options.end_date.end_of_day
          )
        end

        if @options.practitioner_ids.present?
          query = query.joins(:appointment).where(
            appointments: { practitioner_id: @options.practitioner_ids }
          )
        end

        if @options.template_ids.present?
          query = query.where(
            treatment_template_id: @options.template_ids
          )
        end


        if @options.status.present?
          query = query.where(
            status: @options.status
          )
        end

        query.order(id: :desc)
      end

      def calculate
        @results = {}
        @results[:paginated_treatment_notes] = treatment_notes_query.page(options.page)
      end
    end
  end
end
