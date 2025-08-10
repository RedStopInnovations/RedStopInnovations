module Reports
  class TreatmentNotesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :treatment_note_reports
    end

    def list_all
      ahoy_track_once 'View list all treatment notes report'

      @options = parse_list_all_options
      @report = Report::TreatmentNote::ListAll.new(current_business, @options)

      respond_to do |f|
        f.html
        f.csv do
          send_data(
            @report.as_csv,
            filename: "treatment_notes_#{Time.current.strftime('%Y%m%d')}.csv"
          )
        end
      end
    end

    def draft_treatment_notes
      ahoy_track_once 'View draft treatment notes report'

      redirect_to reports_list_all_treatment_notes_path
    end

    def appointments_without_treatment_note
      ahoy_track_once 'View appointments without treatment note report'

      @options = parse_appointments_without_treatment_note_options
      @report = Report::TreatmentNote::AppointmentsWithoutTreatmentNote.make current_business, @options

      respond_to do |f|
        f.html
        f.csv do
          send_data(
            @report.as_csv,
            filename: "appointments_without_treatment_note_#{Time.current.strftime('%Y%m%d')}.csv"
          )
        end
      end
    end

    def triggers_by_word
      ahoy_track_once 'View search treatments for word report'

      @trigger_words = current_business.
        trigger_words.
        includes(:trigger_report).
        page
    end

    def triggers_by_category
      ahoy_track_once 'View search treatments for category report'

      @trigger_categories = current_business.
        trigger_categories.
        includes(:words, :trigger_report).
        page
    end

    private

    def parse_list_all_options
      options = Report::TreatmentNote::ListAll::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_date
        options.end_date = params[:end_date].to_date
        unless options.start_date <= options.end_date
          options.start_date = nil
          options.end_date = nil
        end
      end

      if options.start_date.blank? || options.end_date.blank?
        options.start_date = 30.days.ago.to_date
        options.end_date = Date.today
      end

      if params[:name].present?
        options.name = params[:name].to_s
      end

      if params[:template_ids].is_a?(Array)
        options.template_ids = params[:template_ids]
      else
        options.template_ids = []
      end

      if params[:status].present?
        options.status = params[:status].to_s
      end

      if params[:page]
        options.page = params[:page].to_i
      end

      options
    end

    def parse_appointments_without_treatment_note_options
      options = Report::TreatmentNote::AppointmentsWithoutTreatmentNote::Options.new

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
  end
end
