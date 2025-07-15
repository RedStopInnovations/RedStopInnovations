module App
  module DataExport
    class ExportsController < ApplicationController
      include HasABusiness

      before_action do
        authorize! :export, :all
      end

      def patient_letters
        @options = parse_export_patient_letters_options
        export = Export::PatientLettersCsv.make(current_business, @options)

        respond_to do |f|
          f.html
          f.csv { send_data export.to_csv, filename: "letters_export_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      end

      def patients
        export = Export::Patients.make(current_business, parse_export_patients_options)

        respond_to do |f|
          f.html

          f.csv do
            if params[:csv_type] == 'xero'
              send_data export.as_xero_import_csv, filename: "clients_export_#{Time.current.strftime('%Y%m%d')}.csv"
            else
              send_data export.as_csv, filename: "clients_export_#{Time.current.strftime('%Y%m%d')}.csv"
            end
          end
        end
      end

      def contacts
        export = Export::Contacts.make(current_business, parse_export_options)

        respond_to do |f|
          f.html
          f.csv { send_data export.as_csv, filename: "contacts_export_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      end

      def appointment_types
        export = Export::AppointmentTypes.make(current_business)
        respond_to do |format|
          format.csv { send_data export.to_csv, filename: "appointment_types_export_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      end

      def billable_items
        export = Export::BillableItems.make(current_business)
        respond_to do |format|
          format.csv { send_data export.to_csv, filename: "billable_items_export_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      end

      def products
        export = Export::Products.make(current_business)
        respond_to do |format|
          format.csv { send_data export.to_csv, filename: "products_export_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      end

      def practitioner_documents
        @practitioners = current_business.practitioners.active.includes(:documents).to_a
        begin
          zip_name = "practitioner_documents_export_#{Time.current.strftime('%Y%m%d')}.zip"
          temp_dir = Dir.mktmpdir
          zip_path = File.join(temp_dir, zip_name)
          Zip::File::open(zip_path, true) do |zipfile|
            @practitioners.each do |pract|
              pract_folder = pract.full_name.to_s.parameterize(separator: '_')
              pract_folder << "__#{pract.id}"
              pract.documents.each do |doc|
                if doc.document.file.exists?
                  zipfile.get_output_stream("#{pract_folder}/#{doc.type}.#{doc.document.file.extension}") do |io|
                    io.write doc.document.file.read
                  end
                end
              end
            end
          end
          File.open(zip_path, 'rb') do |zf|
            send_data(
              zf.read,
              filename: zip_name,
              type: "application/zip",
              disposition: 'attachment',
              stream: true,
              buffer_size: '4096'
            )
          end
        ensure
          FileUtils.rm_rf temp_dir if temp_dir
        end
      end

      def users
        export = Export::Users.make(current_business)
        respond_to do |format|
          format.csv { send_data export.to_csv, filename: "users_export_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      end

      def communications
        @options = parse_export_communications_options

        respond_to do |f|
          f.html
          f.csv {
            export = Export::Communications.make(current_business, @options)
            send_data export.to_csv, filename: "messages_export_#{Time.current.strftime('%Y%m%d')}.csv"
          }
        end
      end

      def practitioners_timeable_settings
        export = Export::PractitionerBusinessHours.make(current_business)

        respond_to do |format|
          format.csv {
            send_data export.to_csv, filename: "practitioners_timetable_settings_export#{Time.current.strftime('%Y%m%d')}.csv"
          }
        end
      end

      def waiting_list
        options = parse_export_waiting_list_options
        export = Export::WaitingList.make(current_business, options)

        respond_to do |f|
          f.html
          f.csv do
            send_data export.as_csv, filename: "waiting_list_export_#{Time.current.strftime('%Y%m%d')}.csv"
          end
        end
      end

      private

      def parse_export_waiting_list_options
        options = {}

        if params[:date_start].present?
          begin
            options[:date_start] = params[:date_start].to_date
          rescue => e
          end
        end

        if params[:date_end].present?
          begin
            options[:date_end] = params[:date_end].to_date
          rescue => e
          end
        end

        if params[:professions].present? && params[:professions].is_a?(Array)
          options[:professions] = params[:professions].flatten
        end

        if params[:include_scheduled].present? && params[:include_scheduled].to_s == '1'
          options[:include_scheduled] = true
        end

        options
      end

      def parse_export_options
        options = {}

        if params[:start_date].present?
          begin
            options[:start_date] = params[:start_date].to_date
          rescue => e
          end
        end

        if params[:end_date].present?
          begin
            options[:end_date] = params[:end_date].to_date
          rescue => e
          end
        end

        options
      end

      def parse_export_patients_options
        options = {}

        if params[:create_date_start].present?
          begin
            options[:create_date_start] = params[:create_date_start].to_date
          rescue => e
          end
        end

        if params[:create_date_end].present?
          begin
            options[:create_date_end] = params[:create_date_end].to_date
          rescue => e
          end
        end

        if params[:contact_ids].present? && params[:contact_ids].is_a?(Array)
          options[:contact_ids] = params[:contact_ids]
        end

        options[:include_archived] = ['1', true, 1].include? params[:include_archived]

        options
      end

      def parse_export_communications_options
        options_h = {}

        if params[:start_date].present?
          begin
            options_h[:start_date] = params[:start_date].to_date
          rescue => e
          end
        else
          options_h[:start_date] = 30.days.ago.to_date
        end

        if params[:end_date].present?
          begin
            options_h[:end_date] = params[:end_date].to_date
          rescue => e
          end
        else
          options_h[:end_date] = Date.today
        end

        if params[:recipient_type].present?
          begin
            options_h[:recipient_type] = params[:recipient_type].to_s
          rescue => e
          end
        end

        if params[:category].present?
          options_h[:category] = params[:category].to_s
        end

        if params[:message_type].present?
          options_h[:message_type] = params[:message_type].to_s
        end

        Export::Communications::Options.new options_h
      end

      def parse_export_patient_letters_options
        options_h = {}

        if params[:start_date].present? && params[:end_date].present?
          begin
            options_h[:start_date] = params[:start_date].to_date
            options_h[:end_date] = params[:end_date].to_date
          rescue => e
          end
        else
          options_h[:start_date] = 30.days.ago.to_date
          options_h[:end_date] = Date.today
        end

        if params[:letter_template_ids].present? && params[:letter_template_ids].is_a?(Array)
          options_h[:letter_template_ids] = params[:letter_template_ids]
        end

        Export::PatientLettersCsv::Options.new options_h
      end
    end
  end
end
