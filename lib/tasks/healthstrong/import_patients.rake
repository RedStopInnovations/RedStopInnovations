#bin/rails healthstrong:import_patients business_id=123 csv=tmp/data.csv geocode=1
namespace :healthstrong do
  task import_patients: :environment do
    DOB_FORMAT = '%m/%d/%Y'
    working_dir = Rails.root.join('tmp/healthstrong_import_patients')
    FileUtils.mkdir_p working_dir.to_path

    current_ts = Time.now.to_i
    log_path = working_dir.join("#{current_ts}_log.log").to_path
    @logger = Logger.new log_path

    class ImportPatientContact < ::ActiveRecord::Base
      self.table_name = 'patient_contacts'
      self.inheritance_column = nil

      TYPE_REFERRER    = 'Referrer'
      TYPE_INVOICE_TO  = 'Invoice to'
    end

    class ImportPatient < ::ActiveRecord::Base
      self.table_name = 'patients'

      def address_for_geocode
        [address1, city, state, postcode, country].join(', ')
      end
    end

    def log(what)
      puts what
      @logger.info what
    end

    def map_patient_attrs(input_csv_row)
      attrs = {
        first_name: input_csv_row['First Name'].to_s.strip.presence,
        last_name: input_csv_row['Last Name'].to_s.strip.presence,
        address1: input_csv_row['Address Line 1'].to_s.strip.presence,
        address2: input_csv_row['Address Line 2'].to_s.strip.presence,
        mobile: input_csv_row['Mobile'].to_s.strip.presence,
        phone: input_csv_row['Phone'].to_s.strip.presence,
        email: input_csv_row['Email'].to_s.strip.presence,
        city: input_csv_row['City'].to_s.strip.presence,
        state: input_csv_row['State'].to_s.strip.presence,
        postcode: input_csv_row['Postcode'].to_s.strip.presence,
        country: (input_csv_row['Country'].to_s.strip == 'Australia') ? 'AU' : input_csv_row['Country'].to_s.strip,
        reminder_enable: input_csv_row['Reminder Enable'].to_s.strip == 'Yes'
      }

      if input_csv_row['DOB'].to_s.strip.present?
        attrs[:dob] = Date.strptime(input_csv_row['DOB'], DOB_FORMAT).strftime('%Y-%m-%d')
      end

      if attrs[:mobile].present?
        attrs[:mobile_formated] = TelephoneNumber.parse(attrs[:mobile], attrs[:country]).e164_number
      end

      attrs
    end

    business_id = ENV['business_id']
    input_csv_path = ENV['csv']

    @perform_geocode = ['1', '1'].include?(ENV['geocode'])

    if business_id.blank? || input_csv_path.blank?
      raise ArgumentError, "Business ID or input CSV path is missing!"
    end

    @business = Business.find(business_id)
    import_timestamp = Time.current

    log "Starting import clients for business: ##{ @business.id } - #{ @business.name }"

    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp

    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end

    imported_count = 0
    row_index = 0
    failed_indexes = []
    output_csv_path = working_dir.join("#{current_ts}_output.csv").to_path

    CSV.open(output_csv_path, "wb") do |output_csv|
      output_csv << [
        "first_name", "last_name", "dob", "email", "mobile", "phone",
        "address1", "address2", "city", "state", "postcode", "country",
        "reminder_enable", "lat", "lng", "referrer_contact_id", "invoice_to_contact_id", 'imported_id'
      ]

      CSV.foreach(Rails.root.join(input_csv_path), headers: true) do |row|
        begin
          input_csv_row = row.to_h
          log "##{row_index} - #{row.fetch('First Name')} #{row.fetch('Last Name')} - DOB: #{row.fetch('DOB')}"

          # @TODO: check if patient is already import?
          import_attrs = map_patient_attrs input_csv_row
          import_patient = ImportPatient.new import_attrs
          import_patient.assign_attributes(
            business_id: @business.id,
            full_name: [import_patient.first_name, import_patient.last_name].join(' '),
            created_at: import_timestamp,
            updated_at: import_timestamp,
          )

          if @perform_geocode
            begin
              lat, lng = Geocoder.coordinates(import_patient.address_for_geocode)
              sleep(0.1)
              if lat.present? && lng.present?
                import_patient.latitude = lat
                import_patient.longitude = lng
              end
            rescue => e
              puts "Geocode for `#{import_patient.address_for_geocode}` failed. Error: #{e.message}"
            end
          end

          import_patient.save!

          referrer_contact_id = input_csv_row['Referrers CRN'].strip.present? ? input_csv_row['Referrers CRN'].strip.to_i : nil
          if referrer_contact_id && @business.contacts.where(id: referrer_contact_id).exists?
            ImportPatientContact.create!(
              patient_id: import_patient.id,
              contact_id: referrer_contact_id,
              type: ImportPatientContact::TYPE_REFERRER,
              created_at: import_timestamp,
              updated_at: import_timestamp,
            )
          end

          invoice_to_contact_id = input_csv_row['Invoice To CRN'].strip.present? ? input_csv_row['Invoice To CRN'].strip.to_i : nil
          if invoice_to_contact_id && @business.contacts.where(id: invoice_to_contact_id).exists?
            ImportPatientContact.create!(
              patient_id: import_patient.id,
              contact_id: invoice_to_contact_id,
              type: ImportPatientContact::TYPE_INVOICE_TO,
              created_at: import_timestamp,
              updated_at: import_timestamp,
            )
          end

          imported_count += 1

          output_csv << [
            import_patient.first_name,
            import_patient.last_name,
            import_patient.dob.try(:strftime, '%Y-%m-%d'),
            import_patient.email,
            import_patient.mobile,
            import_patient.phone,
            import_patient.address1,
            import_patient.address2,
            import_patient.city,
            import_patient.state,
            import_patient.postcode,
            import_patient.country,
            import_patient.reminder_enable,
            import_patient.latitude,
            import_patient.longitude,
            input_csv_row['Referrers CRN'].strip,
            input_csv_row['Invoice To CRN'].strip,
            import_patient.id
          ]
        rescue => e
          failed_indexes << row_index
          log "ERROR: Row ##{row_index}| Message: #{e.message}"
        end

        row_index += 1

        if (row_index % 200) == 0
          log "Sleeping ... zzZ"
          sleep(1)
        end
      end
    end

    log "No. rows:     #{row_index}"
    log "Imported:     #{imported_count}"
    log "Failed rows:  #{failed_indexes.count}"
    unless failed_indexes.empty?
      log "Failed row indexes: [#{failed_indexes.join(',')}]"
    end

    log "Input CSV:   #{input_csv_path}"
    log "Output CSV:  #{output_csv_path}"
    log "Log:         #{log_path}"
  end
end
