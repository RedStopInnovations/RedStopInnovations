class PatientsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  INSTANCE_ACTIONS = [
    :show, :edit, :update, :destroy,
    :invoices, :appointments, :payments,
    :merge, :possible_duplicates,
    :archive, :unarchive,
    :outstanding_invoices,
    :invoice_info,
    :edit_access, :update_access,
    :access_disallowed,
    :update_card, :delete_card,
    :open_in_physitrack,
    :update_important_notification,
    :contacts,
    :credit_card_info,
    :edit_payment_methods,
    :update_payment_methods,
  ]

  before_action :set_patient, only: INSTANCE_ACTIONS
  before_action :authorize_patient_access, only: INSTANCE_ACTIONS, except: :access_disallowed

  def index
    if need_authorize_patient_access?(current_user)
      @search_query = current_business.patients.where(id: PatientAccess.where(user_id: current_user.id).pluck(:patient_id))
    else
      @search_query = current_business.patients
    end

    if !params[:include_archived].present?
      @search_query = @search_query.where(archived_at: nil)
    end

    @ransack_params = params[:q].try(:to_unsafe_h) || {}

    main_keyword = @ransack_params[:first_name_or_last_name_or_full_name_or_email_or_mobile_or_phone_cont].to_s.strip.presence

    if main_keyword && (main_keyword =~ /\A\d+\z/) &&
      main_keyword.to_i < 2147483648 # Less than max 4 bytes integer. Will fix by increase the limit of "patients.id" column
      @ransack_params[:id_eq] = main_keyword.to_i
      @ransack_params[:m] = 'or'
    end

    @search_query = @search_query.ransack(@ransack_params)
    @patients = @search_query.
                result.
                includes(:tags).
                order(last_name: :asc).
                page(params[:page])
  end

  def show
    respond_to do |f|
      f.html
      f.json
    end
  end

  def new
    authorize! :create, Patient
    @create_patient_form = CreatePatientForm.new
  end

  def edit
    @update_patient_form = UpdatePatientForm.hydrate(@patient)
  end

  def create
    authorize! :create, Patient

    @create_patient_form = CreatePatientForm.new(create_patient_params)

    if @create_patient_form.valid?
      created_patient = CreatePatientService.new.call(current_business, @create_patient_form, current_user)

      created_patient.update(
        patient_contacts_attributes: params[:patient_contacts].try(:values).to_a.map do |pc|
          pc.permit(:id, :contact_id, :type, :for_appointments, :for_invoices, :for_treatment_notes)
        end
      )

      redirect_to patient_url(created_patient), notice: 'The client was successfully created.'
    else
      render :new
    end
  end

  def update
    authorize! :update, Patient

    @update_patient_form = UpdatePatientForm.new(update_patient_params)

    if @update_patient_form.valid?
      UpdatePatientService.new.call(@patient, @update_patient_form, current_user)
      @patient.reload
      @patient.update(
        patient_contacts_attributes: params[:patient_contacts].try(:values).to_a.map do |pc|
          pc.permit(:id, :contact_id, :type, :for_appointments, :for_invoices, :for_treatment_notes, :_destroy)
        end
      )

      redirect_to patient_url(@patient), notice: 'The client was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, Patient
    DeletePatientData.new.call(@patient)
    @patient.destroy_by_author(current_user)

    if @patient.email? && current_business.mailchimp_list_sync_ready?
      BusinessMailchimpSyncPatients.perform_later(
        current_business,
        @patient,
        {
          destroy: true,
          email: @patient.email
        }
      )
    end

    redirect_to patients_url, notice: 'Client was successfully deleted.'
  end

  def invoices
    authorize! :read, Invoice

    @search_query = @patient.invoices.includes(
        :invoice_to_contact, appointment: [:appointment_type], patient_case: [:case_type]
      )
      .ransack(params[:q].try(:to_unsafe_h))

    @invoices = @search_query.result
                             .order('issue_date DESC, created_at DESC')
                             .page(params[:page])
  end

  def appointments
    @wait_lists = @patient.wait_lists.
      not_scheduled.
      order(date: :desc).
      includes(:appointment_type, :practitioner).
      to_a
    @appointments = @patient.appointments.
      includes(:availability, :appointment_type, practitioner: :user)
      .where(availabilities: { hide: false}) # issue 2154
      .order(end_time: :desc)
      .page(params[:page])
  end

  def payments
    authorize! :read, Payment
    @payments = @patient.payments.order(id: :desc).page(params[:page])
  end

  def possible_duplicates
    @patients = FindDuplicatePatientsService.new.call(
      current_business,
      @patient
    )

    respond_to do |f|
      f.js
    end
  end

  def merge
    authorize! :merge, Patient
    MergePatientsService.new.call(
      @patient,
      current_business.patients.where(id: params[:patient_ids].to_a).to_a,
      current_user
    )

    redirect_to patient_url(@patient),
                notice: 'The clients has been successfully merged.'
  end

  def archive
    authorize! :update, Patient
    @patient.archive

    respond_to do |f|
      f.html {
        redirect_back fallback_location: patient_url(@patient),
                    notice: 'The client has been successfully archived.'
      }

      f.json {
        render(
          json: { success: true }
        )
      }
    end

  end

  def unarchive
    authorize! :update, Patient

    @patient.unarchive
    redirect_to patient_url(@patient),
                notice: 'The client has been successfully actived.'
  end

  def invoice_info
    @patient_presenter = PatientPresenter.new(@patient)
  end

  def outstanding_invoices
    @outstanding_invoices = @patient.invoices.not_paid.order(issue_date: :asc)
    respond_to do |f|
      f.json
    end
  end

  def edit_access
    authorize! :manage_access, @patient
    respond_to do |f|
      f.js
    end
  end

  def edit_payment_methods
    authorize! :update, @patient
    respond_to do |f|
      f.js
    end
  end

  def update_payment_methods
    authorize! :update, @patient

    @patient.assign_attributes update_payment_methods_params
    @patient.save(validate: false) # TODO: make a separate form class
    flash[:notice]= 'The payment method has been successfully updated.'

    respond_to do |f|
      f.js
    end
  end

  def update_access
    authorize! :manage_access, @patient
    @result = UpdatePatientAccessService.new.call(@patient, params.permit(user_ids: []))
    respond_to do |f|
      f.js
    end
  end

  def update_card
    respond_to do |f|
      f.json do
        begin
          result = UpdatePatientCardService.new.call(
            current_business,
            @patient,
            params.fetch(:token)
          )
          if result.success
            render(
              json: { success: true }
            )
          else
            render(
              json: {
                success: false,
                message: result.error
              }
            )
          end

        rescue StandardError => e
          Sentry.capture_exception(e)
          render(
            json: { success: false },
            status: 500
          )
        end
      end
    end
  end

  def delete_card
    result = DeletePatientCardService.new.call(current_business, @patient)
    if result.success
      flash[:notice] = 'The client card has been successfully deleted.'
    else
      flash[:alert] = result.error
    end
    redirect_to patient_url(@patient)
  end

  def open_in_physitrack
    if !current_business.physitrack_integration_enabled?
      @error = 'Physitrack integration is not enabled for your account.'
    else
      @api_key = ApiKey.active.where(user_id: current_user.id).order(id: :desc).first
      if @api_key.nil?
        @error = 'Your API key is not created yet.'
      else
        @query = Physitrack::Sso::QueryBuilder.build_patient_creation_query(
          @patient, @api_key.token
        )
      end
    end

    if @error.nil?
      render layout: false
    end
  end

  def update_important_notification
    content = params[:important_notification].strip
    @patient.update_attribute :important_notification, content
    render json: { success: true }
  end

  def contacts
  end

  def credit_card_info
    @stripe_customer = @patient.stripe_customer
    respond_to do |f|
      f.json do
        if @stripe_customer
          render json: {
            card: {
              last4: @stripe_customer.card_last4,
              updated_at: @stripe_customer.updated_at
            }
          }
        else
          render json: {card: nil}
        end
      end
    end
  end

  private

  def set_patient
    @patient = current_business.patients.find(params[:id])
  end

  def create_patient_params
    params.require(:patient).permit(
      :title,
      :first_name,
      :last_name,
      :phone,
      :mobile,
      :email,
      :address1,
      :address2,
      :city,
      :state,
      :postcode,
      :country,
      :dob,
      :gender,
      :reminder_enable,
      :general_info,
      :extra_invoice_info,
      :next_of_kin,
      :nationality,
      :aboriginal_status,
      :spoken_languages,
      :accepted_privacy_policy,
      tag_ids: [],
    )
  end

  def update_patient_params
    create_patient_params
  end

  def update_payment_methods_params
    params.require(:patient).permit(
      # Medicare details
      :medicare_card_number,
      :medicare_card_irn,
      :medicare_referrer_name,
      :medicare_referrer_provider_number,
      :medicare_referral_date,

      # DVA details
      :dva_file_number,
      :dva_hospital,
      :dva_card_type,
      :dva_white_card_disability,
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
      :ndis_fund_management,
      :ndis_diagnosis,

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
      :hi_patient_number,
      :hi_manager_name,
      :hi_manager_email,
      :hi_manager_phone,

      # STRC details
      :strc_company_name,
      :strc_company_phone,
      :strc_invoice_to_name,
      :strc_invoice_to_email,
    )
  end
end
