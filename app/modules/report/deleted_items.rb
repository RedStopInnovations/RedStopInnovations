module Report
  class DeletedItems
    attr_reader :business, :results, :options

    def self.make(business, options)
      new(business, options)
    end

    def initialize(business, options)
      @business = business
      @options = options
      parse_options
      calculate
    end

    def as_csv
      resource_type_display_name_map = {
        'Appointment' => 'Appointment',
        'AppointmentType' => 'Appointment type',
        'Patient' => 'Client',
        'Contact' => 'Contact',
        'AccountStatement' => 'Account statement',
        'Invoice' => 'Invoice',
        'Payment' => 'Payment',
        'TreatmentTemplate' => 'Treatment note template',
        'Product' => 'Product',
        'BillableItem' => 'Billable item',
      }

      CSV.generate(headers: true) do |csv|
        csv << [
          "Resource", "Resource details", "Associated client ID", "Associated client", "Deleted by", "Deleted on"
        ]

        items_query.each do |row|
          delete_by_cell =
            case row.author_type
            when 'User'
              row.author&.full_name
            when 'AdminUser'
              "System admin"
            end

          resource = row.resource

          resource_cell_lines = []

          case resource
          when Invoice
            resource_cell_lines << "Number: #{ resource.invoice_number }"
            resource_cell_lines << "Issue date: #{ resource.issue_date.strftime(I18n.t('date.common')) }"
          when Appointment
          resource_cell_lines << "Date: #{ resource.start_time.strftime(I18n.t('date.common')) }"
          resource_cell_lines << "Practitioner: #{ resource.practitioner&.full_name }"
          resource_cell_lines << "Type: #{ resource.appointment_type&.name }"
          when AccountStatement
            resource_cell_lines << "Number: #{resource.number}"
          when Patient
            resource_cell_lines << "Name: #{resource.full_name}"
            resource_cell_lines << "DOB: #{resource.dob.try(:strftime, I18n.t('date.dob'))}"
          when Contact
            resource_cell_lines << "Name: #{resource.business_name}"
          when AppointmentType
            resource_cell_lines << "Name: #{resource.name}"
          when TreatmentTemplate
            resource_cell_lines << "Name: #{resource.name}"
          when Product
            resource_cell_lines << "Name: #{resource.name}"
            resource_cell_lines << "Code: #{resource.item_code}"
          when BillableItem
            resource_cell_lines << "Name: #{resource.name}"
            resource_cell_lines << "Number: #{resource.item_number}"
          when Payment
            resource_cell_lines << "Payment date: #{resource.payment_date.strftime(I18n.t('date.common'))}"
            resource_cell_lines << "Amount: #{resource.amount}"
          end

          resource_cell = [
            resource_type_display_name_map[row.resource_type] || row.resource.resource_type,
            "ID: #{row.resource_id}"
          ].join("\n")

          associated_patient = row.associated_patient

          csv << [
            resource_cell,
            resource_cell_lines.join("\n"),
            associated_patient&.id,
            associated_patient&.full_name,
            delete_by_cell,
            row.deleted_at.strftime('%d %b, %Y %l:%M%P')
          ]
        end
      end
    end

    private

    def items_query
      query = DeletedResource.where(
        business_id: business.id,
        deleted_at: options[:start_date].beginning_of_day..options[:end_date].end_of_day
      ).
      order(deleted_at: :desc).
      includes(:author, :resource, :associated_patient)

      if options[:resource_types].present?
        query = query.where(resource_type: options[:resource_types])
      end

      query
    end

    def parse_options
      if options[:resource_types] && options[:resource_types].is_a?(Array)
        options[:resource_types] = [
          'Appointment', 'AppointmentType', 'Patient', 'AccountStatement', 'Contact',
          'Invoice', 'Payment', 'TreatmentTemplate', 'Product', 'BillableItem'
        ] & options[:resource_types]
      end

      options[:start_date] = options[:start_date].try(:to_date) || Time.current.beginning_of_month.to_date
      options[:end_date] = options[:end_date].try(:to_date) || Date.current
    end

    def calculate
      @results = {}

      @results[:paginated_deleted_resources] = items_query.page(options[:page]).per(50)
    end
  end
end
