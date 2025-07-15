module Report
  module Transactions
    class InvoicesRaised
      class Options
        attr_accessor :start_date,
                      :end_date,
                      :practitioner_ids,
                      :billable_item_ids,
                      :practitioner_group_id,
                      :contact_ids,
                      :has_tax,
                      :billing_type,
                      :page

        def initialize(attrs = {})
          @contact_ids = attrs[:contact_ids]
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @practitioner_ids = attrs[:practitioner_ids]
          @billable_item_ids = attrs[:billable_item_ids]
          @practitioner_group_id = attrs[:practitioner_group_id]
          @billing_type = attrs[:billing_type]
        end

        def to_params
          {
            start_date: start_date.strftime("%Y-%m-%d"),
            end_date: end_date.strftime("%Y-%m-%d"),
            contact_ids: contact_ids,
            has_tax: has_tax,
            practitioner_ids: practitioner_ids,
            billable_item_ids: billable_item_ids,
            practitioner_group_id: practitioner_group_id,
            billing_type: billing_type,
          }
        end
      end

      attr_reader :business, :options, :result

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def billable_items_query
        query = BillableItem.joins(invoice_items: :invoice)
          .select(
            "billable_items.*,
            SUM(invoice_items.quantity) AS items_count,
            SUM(invoice_items.amount) AS total_amount"
          )
          .where('invoices.issue_date' => options.start_date..options.end_date)
          .where('invoices.business_id' => business.id)
          .group("billable_items.id")
          .order("billable_items.name ASC")

        if options.contact_ids.present?
          query = query.where('invoices.invoice_to_contact_id' => options.contact_ids)
        end

        if options.billable_item_ids.present?
          query = query.where(id: options.billable_item_ids)
        end

        if options.practitioner_ids.present? || options.practitioner_group_id.present?
          query = query.where('invoices.practitioner_id' => report_practitioner_ids)
        end

        if options.has_tax == 1
          query = query.where('invoices.amount_ex_tax <> invoices.amount')
        elsif options.has_tax == 0
          query = query.where('invoices.amount_ex_tax = invoices.amount')
        end

        if options.billing_type == Appointment.name
          query = query.where('invoices.appointment_id IS NOT NULL')
        elsif options.billing_type == Task.name
          query = query.where('invoices.task_id IS NOT NULL')
        elsif options.billing_type == 'NOT_SPECIFIED'
          query = query.where('invoices.appointment_id IS NULL AND invoices.task_id IS NULL')
        end

        query.load
      end

      def products_query
        query = Product.joins(invoice_items: :invoice)
          .select(
            "products.*,
            SUM(invoice_items.quantity) AS items_count,
            SUM(invoice_items.amount) AS total_amount"
          )
          .where('invoices.issue_date' => options.start_date..options.end_date)
          .where('invoices.business_id' => business.id)
          .group("products.id")
          .order("products.name ASC")

        if options.contact_ids.present?
          query = query.where('invoices.invoice_to_contact_id' => options.contact_ids)
        end

        if options.practitioner_ids.present? || options.practitioner_group_id.present?
          query = query.where('invoices.practitioner_id' => report_practitioner_ids)
        end

        if options.has_tax == 1
          query = query.where('invoices.amount_ex_tax <> invoices.amount')
        elsif options.has_tax == 0
          query = query.where('invoices.amount_ex_tax = invoices.amount')
        end

        if options.billing_type == Appointment.name
          query = query.where('invoices.appointment_id IS NOT NULL')
        elsif options.billing_type == Task.name
          query = query.where('invoices.task_id IS NOT NULL')
        elsif options.billing_type == 'NOT_SPECIFIED'
          query = query.where('invoices.appointment_id IS NULL AND invoices.task_id IS NULL')
        end

        query.load
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Number",
            "Issue date",
            "Appointment date",
            "Created at",
            "Availability start",
            "Availability end",
            "Appointment time",
            "Client ID",
            "Client",
            "Client active status",
            "Client first name",
            "Client last name",
            "Client email",
            "Client phone",
            "Client mobile",
            "Items",
            "Items code",
            "Amount",
            "Amount excluding tax",
            "Outstanding",
            "Tax",

            "Employee number",
            "Practitioner",
            "Practitioner provider number",
            "Practitioner profession",
            "Practitioner state",
            "Practitioner group",

            "Contact name",
            "Contact ID",
            "Contact's client ID number",

            "Account statement number"
          ]

          invoices_query.preload(
            :items,
            :account_statements,
            :invoice_to_contact,
            :practitioner,
            patient: :id_numbers,
            appointment: [:arrival]
          ).find_in_batches(batch_size: 200) do |invoices|
            invoices.each do |invoice|
              patient = invoice.patient
              pract = invoice.practitioner
              appt = invoice.appointment
              practitioner_group_col = if pract
                pract.groups.to_a.map(&:name).join(', ')
              end

              contact = invoice.invoice_to_contact
              invoice_items_lines = []
              invoice_items_code_lines = []

              invoice.items.each do |item|
                invoice_items_lines << item.unit_name
                invoice_items_code_lines << item.item_number
              end

              invoice_items_cell = invoice_items_lines.join("\n")
              invoice_items_code_cell = invoice_items_code_lines.join("\n")

              contact_client_id_cell = nil
              if contact
                contact_client_id_cell = patient.id_numbers.to_a.select do |id_number|
                  id_number.contact_id == contact.id
                end.map(&:id_number).join(', ')
              end

              account_statement_number_col = invoice.account_statements.pluck(:number).join(', ')

              csv << [
                invoice.invoice_number.to_s,
                invoice.issue_date.strftime('%d %b, %Y').to_s,
                appt&.start_time&.strftime('%d %b, %Y').to_s,
                invoice.created_at,
                appt&.start_time&.strftime('%l:%M%P').to_s,
                appt&.end_time&.strftime('%l:%M%P').to_s,
                appt&.arrival&.arrival_at&.strftime('%l:%M%P').to_s,
                patient.id,
                patient.full_name,
                (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
                patient.first_name,
                patient.last_name,
                patient.email,
                patient.phone,
                patient.mobile,
                invoice_items_cell,
                invoice_items_code_cell,
                invoice.amount.to_f.round(2).to_s,
                invoice.amount_ex_tax.to_f.round(2).to_s,
                invoice.outstanding.to_f.round(2).to_s,
                invoice.tax_amount.to_f.round(2).to_s,
                pract&.user&.employee_number,
                pract&.full_name,
                pract&.medicare,
                pract&.profession,
                pract&.state,
                practitioner_group_col,
                contact&.business_name,
                contact&.id,
                contact_client_id_cell,
                account_statement_number_col
              ]
            end
          end
        end
      end

      # Export in format of Xero Sales CSV to import
      def as_xero_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            '*ContactName',
            'EmailAddress',
            'POAddressLine1',
            'POAddressLine2',
            'POAddressLine3',
            'POAddressLine4',
            'POCity',
            'PORegion',
            'POPostalCode',
            'POCountry',
            '*InvoiceNumber',
            'Reference',
            '*InvoiceDate',
            '*DueDate',
            'InventoryItemCode',
            '*Description',
            '*Quantity',
            '*UnitAmount',
            'Discount',
            '*AccountCode',
            '*TaxType',
            'TrackingName1',
            'TrackingOption1',
            'TrackingName2',
            'TrackingOption2',
            'Currency',
            'BrandingTheme'
          ]

          invoice_number_prefix = 'INV-'

          invoices_query.preload(
            :invoice_to_contact, :patient, :items, :practitioner
          ).find_in_batches(batch_size: 200) do |invoices|
            invoices.each do |invoice|
              pract = invoice.practitioner
              patient = invoice.patient
              invoice_to_contact = invoice.invoice_to_contact

              invoice.items.each do |item|
                inventory_item_code = item.item_number

                tax_type =
                  if item.tax_rate
                    'GST on Income'
                  else
                    'GST Free Income'
                  end

                reference =
                    [
                      "Practitioner name: #{pract&.full_name}",
                      "Provider number: #{invoice.provider_number.presence || pract&.medicare}",
                      "Date of service: #{invoice.service_date&.strftime('%d/%m/%Y')}",
                      "Client name: #{patient.full_name}",
                      "Client DOB: #{patient.dob.try(:strftime, '%d/%m/%Y')}"
                    ].join(', ')

                account_code = '200'

                csv << [
                  invoice_to_contact ? invoice_to_contact.business_name : patient.full_name, # '*ContactName'
                  invoice_to_contact ? invoice_to_contact.email : patient.email, # 'EmailAddress'
                  invoice_to_contact ? invoice_to_contact.address1 : patient.address1, # 'POAddressLine1'
                  invoice_to_contact ? invoice_to_contact.address2 : patient.address2, # 'POAddressLine2'
                  nil, # 'POAddressLine3'
                  nil, # 'POAddressLine4'
                  invoice_to_contact ? invoice_to_contact.city : patient.city, # 'POCity'
                  invoice_to_contact ? invoice_to_contact.state : patient.state, # 'PORegion'
                  invoice_to_contact ? invoice_to_contact.postcode : patient.postcode, # 'POPostalCode'
                  invoice_to_contact ? invoice_to_contact.country_name : patient.country_name, #'POCountry'

                  "#{invoice_number_prefix}#{invoice.invoice_number}", # 'InvoiceNumber'
                  reference, # 'Reference'
                  invoice.issue_date.strftime('%d/%m/%Y'), # 'InvoiceDate'
                  invoice.issue_date.strftime('%d/%m/%Y'), # '*DueDate'
                  inventory_item_code, # 'InventoryItemCode'
                  item.unit_name, # '*Description'
                  item.quantity, # '*Quantity'
                  item.unit_price, # '*UnitAmount'
                  nil, # 'Discount'
                  account_code, # '*AccountCode'
                  tax_type, # '*TaxType'
                  nil, # 'TrackingName1',
                  nil, # 'TrackingOption1'
                  nil, # 'TrackingName2',
                  nil, # 'TrackingOption2'
                  nil, # 'Currency'
                  nil, # 'BrandingTheme'
                ]
              end
            end
          end
        end
      end

      private

      def calculate
        @result = {}
        @result[:invoices] = invoices_query

        @result[:invoices_count] = invoices_query.count
        @result[:total_amount_ex_tax] = invoices_query.sum(:amount_ex_tax)
        @result[:total_amount] = invoices_query.sum(:amount)
        @result[:total_outstanding] = invoices_query.sum(:outstanding)

        paginated_invoices = invoices_query.page(options.page)
          .preload(:patient, :items, :practitioner)
        @result[:paginated_invoices] = paginated_invoices

        @result[:products] = products_query
        @result[:billable_items] = billable_items_query
      end

      def invoices_query
        query = Invoice.where(business_id: business.id)
                        .includes(:patient)
                        .where(issue_date: options.start_date..options.end_date)

        if options.contact_ids.present?
          query = query.where(invoice_to_contact_id: options.contact_ids)
        end

        if options.billable_item_ids.present?
          query = query.joins(:items).where(
            items: {
              invoiceable_type: BillableItem.name,
              invoiceable_id: options.billable_item_ids
            }
          )
        end

        if options.practitioner_ids.present? || options.practitioner_group_id.present?
          query = query.where('invoices.practitioner_id' => report_practitioner_ids)
        end

        if options.has_tax == 1
          query = query.where('invoices.amount_ex_tax <> invoices.amount')
        elsif options.has_tax == 0
          query = query.where('invoices.amount_ex_tax = invoices.amount')
        end

        if options.billing_type == Appointment.name
          query = query.where('invoices.appointment_id IS NOT NULL')
        elsif options.billing_type == Task.name
          query = query.where('invoices.task_id IS NOT NULL')
        elsif options.billing_type == 'NOT_SPECIFIED'
          query = query.where('invoices.appointment_id IS NULL AND invoices.task_id IS NULL')
        end

        query.order(issue_date: :DESC)
      end

      def report_practitioner_ids
        @report_practitioner_ids ||=
        if options.practitioner_ids.present?
          options.practitioner_ids
        elsif options.practitioner_group_id.present?
          business.groups.find_by(id: options.practitioner_group_id)&.practitioners&.pluck(:id)
        else
          business.practitioners.pluck(:id)
        end
      end
    end
  end
end
