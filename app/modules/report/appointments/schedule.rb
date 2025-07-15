module Report
  module Appointments
    class Schedule
      class Options
        attr_accessor :practitioner_ids,
                      :appointment_type_ids,
                      :practitioner_group_id,
                      :patient_ids,
                      :start_date,
                      :end_date,
                      :page

        def initialize(options = {})
          @start_date = options[:start_date]
          @end_date = options[:end_date]
          @appointment_type_ids = options[:appointment_type_ids]
          @practitioner_ids = options[:practitioner_ids]
          @practitioner_group_id = options[:practitioner_group_id]
          @patient_ids = options[:patient_ids]
          @page = options[:page]
        end

        def to_params
          {
            start_date: start_date.strftime("%Y-%m-%d"),
            end_date: end_date.strftime("%Y-%m-%d"),
            appointment_type_ids: appointment_type_ids,
            practitioner_ids: practitioner_ids,
            patient_ids: patient_ids,
            practitioner_group_id: practitioner_group_id
          }
        end
      end


      attr_reader :business, :options, :results

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def empty?
        results[:appointments_count].zero?
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Appointment ID",
            "Appointment Date", "Availability Start", "Availability End", "Appointment Time", "Full appointment time",
            "Practitioner", "Practitioner profession", "Practitioner group",
            "Client ID", "Client", "Client first name", "Client last name", "Client mobile", "Client phone", "Client email",
            "Client address line 1", "Client address line 2", "Client city", "Client state", "Client postcode",
            "Client reminder enable",
            "Client active status",
            "Confirmation status",
            "Status",
            "Appointment type", "Appointment duration (minutes)", "Travel distance (km)", "Travel time (minutes)",
            "Invoice To", "Referrer",
            "Created at",
            "Created by",
          ]

          appointments = appointments_query.preload(
            :appointment_type,
            :arrival,
            :availability,
            created_version: :author,
            practitioner: :groups,
            patient: { patient_invoice_to_contacts: :contact, patient_referrer_contacts: :contact }
          ).order("appointments.start_time DESC")

          appointments.find_each do |appt|
            patient = appt.patient
            arrival = appt.arrival
            practitioner = appt.practitioner
            practitioner_group_col = practitioner.groups.to_a.map(&:name).join(';')

            if patient
              invoice_to_col = patient.patient_invoice_to_contacts.map(&:contact).map(&:business_name).join(';')
              referrer_col = patient.patient_referrer_contacts.map(&:contact).map(&:business_name).join(';')
            end

            travel_distance =
              if arrival && arrival.travel_distance
                (arrival.travel_distance.to_f / 1000).round(2)
              else
                nil
              end

            travel_duration =
              if arrival && arrival.travel_duration
                (arrival.travel_duration.to_f / 60).round(2)
              else
                nil
              end

            csv << [
              appt.id,
              appt.start_time.try(:strftime, '%d %b %Y').to_s,
              appt.availability&.start_time.try(:strftime, '%l:%M%P').to_s,
              appt.availability&.end_time.try(:strftime, '%l:%M%P').to_s,
              arrival&.arrival_at.try(:strftime, '%l:%M%P').to_s,
              arrival&.arrival_at,
              practitioner.full_name,
              practitioner.profession,
              practitioner_group_col,
              patient.try(:id),
              patient.try(:full_name),
              patient.try(:first_name),
              patient.try(:last_name),
              patient.try(:mobile),
              patient.try(:phone),
              patient.try(:email),
              patient.try(:address1),
              patient.try(:address2),
              patient.try(:city),
              patient.try(:state),
              patient.try(:postcode),
              patient.reminder_enable? ? 'Yes' : 'No',
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              appt.is_confirmed? ? 'Yes' : nil,
              appt.status.try(:humanize),
              appt.appointment_type.try(:name),
              appt.appointment_type.try(:duration),
              travel_distance,
              travel_duration,
              invoice_to_col,
              referrer_col,
              appt.created_at,
              appt&.created_version&.author&.full_name
            ]
          end
        end
      end

      def as_advanced_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Appointment ID",
            "Appointment date",
            "Appointment time",
            "Full appointment time",
            "Appointment type",
            "Appointment duration (minutes)",

            "Availability start",
            "Availability end",
            "Availability type",
            "Availability subtype",
            "Availability description",
            "Availability duration (minutes)",

            "Practitioner",
            "Practitioner active status",
            "Practitioner profession",
            "Practitioner group",
            "Practitioner employee number",

            "Client ID", "Client", "Client first name", "Client last name", "Client mobile", "Client phone", "Client email",
            "Client address line 1", "Client address line 2", "Client city", "Client state", "Client postcode",
            "Client reminder enable",
            "Client active status",

            "Confirmation status",
            "Status",
            "Travel distance (km)",
            "Travel time (minutes)",
            "Invoice to",
            "Referrer",
            "Created at",
            "Created by",

            'Invoice number', # AM
            'Invoice item name', # AO
            'Invoice item number',
            'Invoice item price', # AP
            'Invoice item variable pricing', # AQ
          ]

          appointments = appointments_query.preload(
            :arrival,
            :availability,
            :invoice,
            created_version: :author,
            practitioner: [:user, :groups],
            appointment_type: { billable_items: {pricing_contacts: :contact} },
            patient: { patient_invoice_to_contacts: :contact, patient_referrer_contacts: :contact }
          ).order("appointments.start_time DESC")

          appointments.find_each do |appt|
            patient = appt.patient
            arrival = appt.arrival
            availability = appt.availability
            practitioner = appt.practitioner
            appointment_type = appt.appointment_type
            practitioner_group_col = practitioner.groups.to_a.map(&:name).join(';')

            if patient
              invoice_to_col = patient.patient_invoice_to_contacts.map(&:contact).map(&:business_name).join(';')
              referrer_col = patient.patient_referrer_contacts.map(&:contact).map(&:business_name).join(';')
            end

            travel_distance =
              if arrival && arrival.travel_distance
                (arrival.travel_distance.to_f / 1000).round(2)
              else
                nil
              end

            travel_duration =
              if arrival && arrival.travel_duration
                (arrival.travel_duration.to_f / 60).round(2)
              else
                nil
              end

            availability_duration = nil

            if availability
              availability_duration = ((availability.end_time - availability.start_time).to_f / 60).round(2)
            end

            issued_invoice = appt.invoice

            issued_invoice_number_col = nil

            invoice_items_name_col =
              invoice_items_number_col =
              invoice_items_price_col =
              invoice_items_variable_pricing_col = nil

            if issued_invoice
              issued_invoice_number_col = issued_invoice.invoice_number
            end

            if appointment_type
              default_billable_items = appointment_type.billable_items.to_a

              invoice_items_name_col = default_billable_items.map(&:name).join(';')
              invoice_items_price_col = default_billable_items.map(&:price).join(';')
              invoice_items_number_col = default_billable_items.map(&:item_number).join(';')

              invoice_items_variable_pricing_list = []

              default_billable_items.each do |bi|
                bi.pricing_contacts.each do |pc|
                  if pc.contact
                    invoice_items_variable_pricing_list << "#{pc.contact.business_name}: #{pc.price}"
                  end
                end
              end

              invoice_items_variable_pricing_col = invoice_items_variable_pricing_list.join(';')
            end

            csv << [
              appt.id,
              appt.start_time.strftime('%d %b %Y'),
              arrival&.arrival_at.try(:strftime, '%l:%M%P').to_s,
              arrival&.arrival_at,
              appointment_type&.name,
              appointment_type&.duration,

              availability&.start_time.try(:strftime, '%l:%M%P').to_s,
              availability&.end_time.try(:strftime, '%l:%M%P').to_s,
              availability&.availability_type&.name,
              availability&.availability_subtype&.name,
              availability&.description,
              availability_duration,

              practitioner.full_name,
              (practitioner.active? ? 'Active' : 'Inactive'),
              practitioner.profession,
              practitioner_group_col,
              practitioner.user&.employee_number,

              patient.try(:id),
              patient.try(:full_name),
              patient.try(:first_name),
              patient.try(:last_name),
              patient.try(:mobile),
              patient.try(:phone),
              patient.try(:email),
              patient.try(:address1),
              patient.try(:address2),
              patient.try(:city),
              patient.try(:state),
              patient.try(:postcode),
              patient.reminder_enable? ? 'Yes' : 'No',
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',

              appt.is_confirmed? ? 'Yes' : nil,
              appt.status.try(:humanize),
              travel_distance,
              travel_duration,
              invoice_to_col,
              referrer_col,
              appt.created_at,
              appt&.created_version&.author&.full_name,

              issued_invoice_number_col, # 'Invoice number'
              invoice_items_name_col, # 'Invoice item name'
              invoice_items_number_col, # 'Invoice item number'
              invoice_items_price_col, # 'Invoice item price'
              invoice_items_variable_pricing_col, # 'Variable pricing'
            ].map(&:presence)
          end
        end
      end

      private

      def calculate
        @results = {
          summary_by_appointment_type: [],
          summary_by_practitioner: [],
          dates_with_appointments: []
        }

        appts_query = appointments_query.preload(
          :practitioner, :invoice, :patient, :appointment_type, :treatment, :arrival, :attendance_proofs_attachments
        )

        appts = appts_query

        @results[:appointments_count] = appts.size
        @results[:practitioners_count] = appointments_query.count('DISTINCT(appointments.practitioner_id)')
        @results[:patients_count] = appointments_query.count('DISTINCT(appointments.patient_id)')

        @results[:summary_by_appointment_type] = build_summary_by_appointment_type
        @results[:summary_by_practitioner] = build_summary_by_practitioner

        paginated_appointments = appts_query.order("appointments.start_time DESC").page(options.page)

        @results[:paginated_appointments] = paginated_appointments
        @results[:dates_with_appointments] = build_dates_with_appointments(paginated_appointments)
      end

      def build_summary_by_appointment_type
        result = []

        appointments_count_by_appt_type_id = appointments_query.group('appointment_type_id').count

        ::AppointmentType.select(:id, :name).where(id: appointments_count_by_appt_type_id.keys).
          order(name: :asc).
          each do |at|
            result << {
              appointment_type: at,
              appointments_count: appointments_count_by_appt_type_id[at.id]
            }
          end

        result
      end

      def build_summary_by_practitioner
        result = []

        appointments_count_by_practitioner_id = appointments_query.group('practitioner_id').count

        Practitioner.select(:id, :full_name).where(id: appointments_count_by_practitioner_id.keys).
          order(full_name: :asc).
          each do |pract|
            result << {
              practitioner: pract,
              appointments_count: appointments_count_by_practitioner_id[pract.id]
            }
          end

        result
      end

      def build_dates_with_appointments(appointments)
        result = []
        appointments.group_by { |appt| appt.start_time.to_date }.
          each do |date, appts|

          result << {
            date: date,
            appointments: appts
          }
        end
        result.sort_by { |row| row[:date] }
      end

      def appointments_query
        query = Appointment.joins(:availability, :practitioner, :appointment_type, :patient)
          .where(appointments: { practitioner_id: report_practitioner_ids })
          .where("patients.deleted_at IS NULL")
          .where("appointments.cancelled_at IS NULL")
          .where("appointments.start_time >= ?", options.start_date.beginning_of_day)
          .where("appointments.start_time <= ?", options.end_date.end_of_day)
          .where(availabilities: {hide: false}) # issue 2154

        query = query.where(patient_id: options.patient_ids) if options.patient_ids.present?
        query = query.where(appointment_type_id: options.appointment_type_ids) if options.appointment_type_ids.present?
        query
      end

      def report_practitioner_ids
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
