module Reports
  class PractitionersController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def practitioner_reviews
      ahoy_track_once 'View practitioner reviews report'

      @reviews = current_business.reviews.page(params[:page])
    end

    def practitioner_performance
      ahoy_track_once 'View practitioner performance report'

      if %i(start_date end_date practitioner_ids practitioner_group_ids include_inactive_practitioner).any? { |key| params.key?(key) }
        @options = parse_practitioner_performance_report_options
        @report = Report::Practitioners::Performance.make current_business, @options

        respond_to do |f|
          f.html
          f.csv { send_data @report.as_csv, filename: "practitioners_performance_#{Time.current.strftime('%Y%m%d')}.csv" }
        end
      else
        @options = default_practitioner_performance_report_options
      end
    end

    # @TODO: remove later
    def practitioner_performance_legacy
      ahoy_track_once 'View practitioner performance report (Legacy)'

      @options = parse_practitioner_performance_legacy_report_options
      @report = Report::Practitioners::PerformanceLegacy.make current_business, @options

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def practitioner_documents
      ahoy_track_once 'View practitioner documents report'

      business = current_business
      query = business.practitioners.active
      join_stat = 'LEFT JOIN practitioner_documents ON practitioner_documents.practitioner_id = practitioners.id'

      @options = parse_practitioner_documents_options

      if @options.type
        join_stat << " AND practitioner_documents.type = '#{@options.type}'"
      end

      today = Date.current.to_date
      case @options.status
      when 'current'
        query = query.where(
          'practitioner_documents.expiry_date >= ?', today
        )
      when 'missing'
        if @options.type.blank?
          query = query.having(
            'COUNT(practitioner_documents.id) < 4'
          )
        else
          query = query.having(
            'COUNT(practitioner_documents.id) = 0'
          )
        end
      when 'expired'
        query = query.where(
          'practitioner_documents.expiry_date < ?', today
        )
      when 'missing_expiry'
        query = query.where(
          'practitioner_documents.id IS NOT NULL AND practitioner_documents.expiry_date IS NULL'
        )
      end

      @practitioners = query.
        joins(join_stat).
        preload(:user, :documents).
        group('practitioners.id').
        page(params[:page])
    end

    def practitioner_travel
      ahoy_track_once 'View practitioner travel report'

      @options = parse_practitioner_travel_options
      @report = Report::Practitioners::Travel.make current_business, @options

      respond_to do |f|
        f.html
        f.csv {
          if params[:_legacy]
            send_data @report.as_legacy_csv, filename: "practitioners_travel_#{Time.current.strftime('%Y%m%d')}.csv"
          else
            send_data @report.as_csv, filename: "practitioners_travel_#{Time.current.strftime('%Y%m%d')}.csv"
          end
        }
      end
    end

    def single_practitioner_travel
      @options = parse_single_practitioner_travel_options
      @report = Report::Practitioners::SinglePractitionerTravel.make current_business, @options

      render layout: false
    end

    def send_practitioner_performance
      ahoy_track_once 'Send practitioner performance report'

      options = parse_practitioner_performance_report_options
      @report = Report::Practitioners::Performance.make current_business, options

      if @report.result[:data].present?
        @report.result[:data].each do |row|
          PractitionerMailer.performance_report_mail(
            row[:practitioner],
            options.start_date,
            options.end_date,
            row
          ).deliver_later
        end
      end

      redirect_back fallback_location: reports_practitioner_performance_path,
                    notice: 'The performance report has been sent to practitioner.'
    end

    # @TODO: remove later
    def send_practitioner_performance_legacy
      ahoy_track_once 'Send practitioner performance report (Legacy)'

      options = parse_practitioner_performance_legacy_report_options
      @report = Report::Practitioners::PerformanceLegacy.make current_business, options

      if @report.result[:data].present?
        @report.result[:data].each do |row|
          PractitionerMailer.performance_report_mail(
            row[:practitioner],
            options.start_date,
            options.end_date,
            row
          ).deliver_later
        end
      end

      redirect_back fallback_location: reports_practitioner_performance_legacy_path,
                    notice: 'The performance report has been sent to practitioner.'
    end

    def practitioner_availability
      ahoy_track_once 'Send practitioner availability report'

      @options = parse_practitioner_availability_repprt_options
      @report = Report::Practitioners::Availability.make current_business, @options

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv, filename: "practitioner_availability_#{Time.current.strftime('%Y%m%d')}.csv" }
      end
    end

    private

    def parse_practitioner_documents_options
      options = {}
      if params[:type].present?
        options[:type] = params[:type].to_s.strip
      end

      if params[:status].present?
        options[:status] = params[:status].to_s.strip
      end
      OpenStruct.new options
    end

    def parse_practitioner_travel_options
      options = Report::Practitioners::Travel::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 30.days.ago.to_date
        options.end_date = Date.current
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      end

      if params[:appointment_type_ids].present? && params[:appointment_type_ids].is_a?(Array)
        options.appointment_type_ids = current_business.appointment_types.
          where(id: params[:appointment_type_ids]).
          pluck(:id)
      end

      if params[:page]
        options.page = params[:page].to_i
      end

      options
    end

    def parse_single_practitioner_travel_options
      options = Report::Practitioners::SinglePractitionerTravel::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 7.days.ago.to_date
        options.end_date = Date.current
      end

      if params[:practitioner_id].present?
        options.practitioner_id = current_business.practitioners.find(params[:practitioner_id]).id
      else
        # TODO: validate and return the convension JSON format
        raise 'Invalid request'
      end

      if params[:appointment_type_ids].present? && params[:appointment_type_ids].is_a?(Array)
        options.appointment_type_ids = current_business.appointment_types.
          where(id: params[:appointment_type_ids]).
          pluck(:id)
      end

      options
    end

    def parse_practitioner_availability_repprt_options
      options = Report::Practitioners::Availability::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 30.days.ago.to_date
        options.end_date = Date.current
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      elsif params[:practitioner_group_ids].present? && params[:practitioner_group_ids].is_a?(Array)
        options.practitioner_group_ids = current_business.groups.
          where(id: params[:practitioner_group_ids]).
          pluck(:id)
      elsif params[:include_inactive_practitioner].present?
        options.include_inactive_practitioner = [1, '1'].include?(params[:include_inactive_practitioner])
      end

      if params[:availability_type_ids].present? && params[:availability_type_ids].is_a?(Array)
        options.availability_type_ids = params[:availability_type_ids].map(&:to_i)
      end

      if params[:page]
        options.page = params[:page].to_i
      end

      options
    end

    # @TODO: remove later
    def parse_practitioner_performance_legacy_report_options
      options = Report::Practitioners::Performance::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 30.days.ago.to_date
        options.end_date = Date.current
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      elsif params[:practitioner_group_ids].present? && params[:practitioner_group_ids].is_a?(Array)
        options.practitioner_group_ids = current_business.groups.
          where(id: params[:practitioner_group_ids]).
          pluck(:id)
      end

      options
    end

    def parse_practitioner_performance_report_options
      options = Report::Practitioners::Performance::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      elsif params[:practitioner_group_ids].present? && params[:practitioner_group_ids].is_a?(Array)
        options.practitioner_group_ids = current_business.groups.
          where(id: params[:practitioner_group_ids]).
          pluck(:id)
      end

      if params[:include_inactive_practitioner]
        options.include_inactive_practitioner = [1, '1'].include?(params[:include_inactive_practitioner])
      end

      if params[:invoice_stats_by_service_date]
        options.invoice_stats_by_service_date = [1, '1'].include?(params[:invoice_stats_by_service_date])
      end

      options
    end

    def default_practitioner_performance_report_options
      options = Report::Practitioners::Performance::Options.new

      options.start_date = 30.days.ago.to_date
      options.end_date = Date.current

      options
    end
  end
end
