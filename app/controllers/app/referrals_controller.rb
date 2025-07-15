module App
  class ReferralsController < ApplicationController
    include HasABusiness

    before_action :set_referral, only: [
      :show, :edit, :update, :approve, :update_progress, :archive, :unarchive,
      :modal_show, :modal_find_practitioners, :update_internal_note,
      :assign_practitioner,
      :reject, :modal_reject_confirmation,
      :find_first_appointment,
      :delete_attachment
    ]

    before_action :deny_approved_referral, only: [:approve]

    def index
      authorize! :read, Referral
      @options = parse_referrals_index_options

      if current_user.is_practitioner? && !current_user.role_administrator? && !current_user.role_supervisor? && !current_user.role_restricted_supervisor?
        @options.practitioner_ids = [current_user.practitioner.id]
      end

      @report = Report::Referral::Summary.new(current_business, @options)

      respond_to do |f|
        f.html do
          @referrals = @report
            .result[:referrals]
            .page(params[:page])
        end

        f.csv do
          send_data @report.as_csv, filename: "referrals_export_#{Time.current.strftime('%Y%m%d')}.csv"
        end
      end
    end

    def modal_show
      authorize! :read, Referral
      render 'modal_show', layout: false
    end

    def new
      authorize! :create, Referral

      @referral_form = AppReferralForm.new(
        type: Referral::TYPE_GENERAL,
        availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID,
        patient: {
          country: current_business.country
        },
        business: current_business
      )
    end

    def create
      authorize! :create, Referral

      @referral_form = AppReferralForm.new(create_referral_params.merge(
        business: current_business
      ))
      @referral_form.patient.referral_type = @referral_form.type

      if @referral_form.valid?
        created_referral = CreateAppReferralService.new.call(current_business, @referral_form)

        respond_to do |f|
          f.html do
            redirect_to app_referral_path(created_referral), notice: 'The referral has been successfully created.'
          end
          f.json do
            render(json: {
              redirect_url: app_referral_path(created_referral),
              message: 'The referral has been successfully created.'
            }, status: 201)
          end
        end
      else
        respond_to do |f|
          f.html do
            flash.now[:alert] = 'Failed to create referral. Please check for form errors.'
            render :new, status: 422
          end
          f.json do
            errors = @referral_form.errors.full_messages + @referral_form.patient.errors.full_messages
            render(
              json: {
                errors: errors,
                message: 'Failed to create referral. Please check for form errors.'
              },
              status: 422
            )
          end
        end
      end
    end

    def edit
      authorize! :edit, Referral

      @referral_form = AppReferralForm.hydrate(@referral)
    end

    def update
      authorize! :update, Referral

      @referral_form = AppReferralForm.new(update_referral_params.merge(
        business: current_business
      ))
      @referral_form.patient.referral_type = @referral_form.type

      if @referral_form.valid?
        UpdateAppReferralService.new.call(@referral, @referral_form)

        respond_to do |f|
          f.html do
            redirect_to app_referral_path(@referral), notice: 'The referral has been successfully updated.'
          end
          f.json do
            render(json: {
              redirect_url: app_referral_path(@referral),
              message: 'The referral has been successfully updated.'
            }, status: 200)
          end
        end
      else
        respond_to do |f|
          f.html do
            flash.now[:alert] = 'Failed to update referral. Please check for form errors.'
            render :edit, status: 422
          end
          f.json do
            errors = @referral_form.errors.full_messages + @referral_form.patient.errors.full_messages
            render(
              json: {
                errors: errors,
                message: 'Failed to update referral. Please check for form errors.'
              },
              status: 422
            )
          end
        end
      end
    end

    def approve
      authorize! :update, Referral

      ApproveReferralService.new.call(current_business, @referral)
      flash[:notice] = 'The referral has been successfully approved.'

      redirect_back fallback_location: app_referral_path(@referral)
    end

    def reject
      authorize! :update, Referral

      if @referral.pending?
        RejectReferralService.new.call(current_business, @referral, reject_reason: params[:reject_reason].presence)
        flash[:notice] = 'The referral has been successfully rejected.'
      else
        flash[:alert] = 'The referral is not in pending status.'
      end

      redirect_back fallback_location: app_referral_path(@referral)
    end

    def modal_reject_confirmation
      authorize! :update, Referral

      render 'modal_reject_confirmation', layout: false
    end

    def update_progress
      @referral.assign_attributes(update_progress_params)
      @referral.save!

      respond_to do |f|
        f.html do
          redirect_back fallback_location: app_referral_path(@referral),
                        notice: 'The referral has been successfully updated.'
        end
        f.js
      end
    end

    def archive
      authorize! :update, Referral
      if !@referral.archived?
        @referral.update_column :archived_at, Time.current
      end

      redirect_back fallback_location: app_referral_path(@referral),
                  notice: 'The referral has been archived.'
    end

    def unarchive
      authorize! :update, Referral
      if @referral.archived?
        @referral.update_column :archived_at, nil
      end

      redirect_back fallback_location: app_referral_path(@referral),
                  notice: 'The referral has been unarchived.'
    end

    def modal_find_practitioners
      authorize! :update, Referral
      practitioners = FindPractitionersReferralService.new.call(@referral)
      render 'modal_find_practitioners', layout: false, locals: { practitioners: practitioners }
    end

    def update_internal_note
      authorize! :update, Referral
      sanitized_note = params[:internal_note].to_s.strip.presence
      @referral.update_column :internal_note, sanitized_note
      render json: { success: true }
    end

    def assign_practitioner
      authorize! :update, Referral
      practitioner = current_business.practitioners.find(params[:practitioner_id])
      @referral.practitioner_id = practitioner.id
      @referral.save!(validate: false)

      render json: { success: true }
    end

    def find_first_appointment
      patient = @referral.patient

      appointment = nil

      if patient
        appointment = Appointment.where(patient_id: patient.id).
          where('start_time >= ?', @referral.created_at).
          where('created_at >= ?', @referral.created_at).
          order(start_time: :asc).
          first
      end

      if appointment
        render json: { appointment: appointment.as_json(only: [:id, :start_time, :created_at]) }
      else
        render json: { appointment: nil }
      end
    end

    def delete_attachment
      attm = @referral.attachments.find(params[:attachment_id])
      attm.destroy

      redirect_back fallback_location: app_referral_path(@referral),
                    notice: 'An attachment has been successfully deleted.'
    end

    def bulk_archive
      authorize! :manage, Referral

      if params[:referral_ids].to_a.present?
        current_business.referrals
          .not_archived
          .where(id: params[:referral_ids].to_a)
          .update_all(archived_at: Time.current)

        redirect_back fallback_location: app_referrals_path,
                      notice: 'The referrals has been successfully archived.'
      else
        redirect_back fallback_location: app_referrals_path,
                      alert: 'The referrals list must not be empty.'
      end
    end

    private

    def referrals_query_scope
      query = current_business.referrals

      if current_user.is_practitioner? && !current_user.role_administrator? && !current_user.role_supervisor?
        query = query.where(practitioner_id: current_user.practitioner.id)
      end

      query
    end

    def set_referral
      @referral = referrals_query_scope.find_by id: params[:id]

      return redirect_to app_referrals_path,
          alert: 'The referral is not exists' unless @referral
    end

    def deny_approved_referral
      if @referral.approved?
        if @referral.business_id == current_business.id
          return redirect_to patient_path(@referral.patient_id),
            notice: 'The referral has been approved.'
        else
          return redirect_to app_referrals_path,
            alert: 'The referral has been approved by other business.'
        end
      end
    end

    def create_referral_params
      params.require(:referral).permit(
        :availability_type_id,
        :practitioner_id,
        :referrer_business_name,
        :referrer_name,
        :referrer_email,
        :referrer_phone,
        :medical_note,
        :priority,
        :referral_reason,
        :type,
        patient: [
          :first_name,
          :last_name,
          :dob,
          :phone,
          :mobile,
          :email,
          :address1,
          :city,
          :state,
          :postcode,
          :country,
          :aboriginal_status,
          :next_of_kin,
          :general_info,

          # Medicare details
          :medicare_card_number,
          :medicare_card_irn,
          :medicare_referrer_name,
          :medicare_referrer_provider_number,
          :medicare_referral_date,

          # DVA details
          :dva_file_number,
          :dva_card_type,
          :dva_referrer_name,
          :dva_referrer_provider_number,
          :dva_referral_date,

          # NDIS details
          :ndis_client_number,
          :ndis_plan_start_date,
          :ndis_plan_end_date,
          :ndis_plan_manager_name,
          :ndis_plan_manager_phone,
          :ndis_plan_manager_email,

          # Home care package details
          :hcp_company_name,
          :hcp_manager_name,
          :hcp_manager_phone,
          :hcp_manager_email,

          # Hospital in the home details
          :hih_hospital,
          :hih_procedure,
          :hih_discharge_date,
          :hih_surgery_date,
          :hih_doctor_name,
          :hih_doctor_phone,
          :hih_doctor_email,

          # Health insurance details
          :hi_company_name,
          :hi_number,
          :hi_manager_name,
          :hi_manager_email,
          :hi_manager_phone,

          # STRC details
          :strc_company_name,
          :strc_company_phone,
          :strc_invoice_to_name,
          :strc_invoice_to_email,
        ],
        professions: [],
        attachments: []
      )
    end

    def update_referral_params
      create_referral_params
    end

    def parse_referrals_index_options
      options = Report::Referral::Summary::Options.new

      if params[:search].present?
        options.search = params[:search]
      end

      if params[:start_date].present?
        options.start_date = params[:start_date].to_s.to_date rescue nil
      end

      if params[:end_date].present?
        options.end_date = params[:end_date].to_s.to_date rescue nil
      end

      if options.start_date.nil? && options.end_date.nil?
        options.start_date = 30.days.ago
        options.end_date = Date.current
      end

      if params[:include_archived].to_s == '1'
        options.include_archived = true
      end

      if params[:without_appointments].to_s == '1'
        options.without_appointments = true
      end

      if params[:status].present?
        options.status = params[:status]
      end

      if params[:reject_reason].present?
        options.reject_reason = params[:reject_reason].to_s.strip
      end

      if params[:referral_type].present?
        options.referral_type = params[:referral_type]
      end

      if params[:practitioner_ids].is_a?(Array) && params[:practitioner_ids].present?
        options.practitioner_ids = params[:practitioner_ids]
      end

      options
    end

    def update_progress_params
      params.require(:referral).permit(
        :receive_referral_date,
        :contact_referrer_date,
        :contact_patient_date,
        :first_appoinment_date,
        :send_treatment_plan_date,
        :send_service_agreement_date,
        :summary_referral
      )
    end
  end
end
