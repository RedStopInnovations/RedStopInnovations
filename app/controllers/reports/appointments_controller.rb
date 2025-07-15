module Reports
  class AppointmentsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def appointments_schedule
      ahoy_track_once 'View appointments schedule report'

      @options = parse_appointments_schedule_options
      @report = Report::Appointments::Schedule.make current_business, @options

      respond_to do |f|
        f.html
        f.csv {

          if params[:csv_type] == 'advanced'
            send_data @report.as_advanced_csv, filename: "appointments_schedule_#{Time.current.strftime('%Y%m%d')}.csv"
          else
            send_data @report.as_csv, filename: "appointments_schedule_#{Time.current.strftime('%Y%m%d')}.csv"
          end

        }
      end
    end

    def uninvoiced_appointments
      ahoy_track_once 'View uninvoiced appointments report'

      @options = parse_uninvoiced_appointments_options
      @report = Report::Appointments::Uninvoiced.make current_business, @options

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def uninvoiced_tasks
      ahoy_track_once 'View uninvoiced tasks report'

      @options = parse_uninvoiced_tasks_options
      @report = Report::Appointments::UninvoicedTasks.make current_business, @options
    end

    def cancelled_appointments
      ahoy_track_once 'View cancelled appointments report'

      @report = Report::Appointments::Cancelled.make current_business, params

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def appointments_incomplete
      ahoy_track_once 'View incomplete appointments report'

      @options = parse_incomplete_options
      @report = Report::Appointments::Incomplete.make(
        current_business,
        @options
      )

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    private

    def parse_appointments_schedule_options
      options = Report::Appointments::Schedule::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 7.days.ago
        options.end_date = Date.current
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      elsif params[:practitioner_group_id].present?
        options.practitioner_group_id = current_business.groups.
          find_by(id: params[:practitioner_group_id]).
          try(:id)
      end


      if params[:appointment_type_ids].present? && params[:appointment_type_ids].is_a?(Array)
        options.appointment_type_ids = current_business.appointment_types.
          where(id: params[:appointment_type_ids]).
          pluck(:id)
      end

      if params[:patient_ids].present? && params[:patient_ids].is_a?(Array)
        options.patient_ids = current_business.patients.
          where(id: params[:patient_ids]).
          pluck(:id)
      end

      if params[:page]
        options.page = params[:page].to_i
      end

     options
    end

    def parse_incomplete_options
      options = Report::Appointments::Incomplete::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 30.days.ago
        options.end_date = Date.current
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      end

      if params[:status].present? && params[:status].is_a?(Array)
        options.status = params[:status]
      end

      if params[:is_no_status].to_s == '1'
        options.is_no_status = true
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

    def parse_uninvoiced_appointments_options
      options = Report::Appointments::Uninvoiced::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 30.days.ago
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

      if params[:patient_ids].present? && params[:patient_ids].is_a?(Array)
        options.patient_ids = current_business.patients.
          where(id: params[:patient_ids]).
          pluck(:id)
      end

      if params[:is_complete].to_s == '1'
        options.is_complete = true
      end

      if params[:page]
        options.page = params[:page].to_i
      end

     options
    end

    def parse_uninvoiced_tasks_options
      options = Report::Appointments::UninvoicedTasks::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 30.days.ago
        options.end_date = Date.current
      end

      if params[:user_ids].present? && params[:user_ids].is_a?(Array)
        options.user_ids = current_business.users.
          where(id: params[:user_ids]).
          pluck(:id)
      end

      if params[:patient_ids].present? && params[:patient_ids].is_a?(Array)
        options.patient_ids = current_business.patients.
          where(id: params[:patient_ids]).
          pluck(:id)
      end

      if params[:page]
        options.page = params[:page].to_i
      end

     options
    end

  end
end
