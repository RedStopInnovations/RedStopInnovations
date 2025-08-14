class PatientCasesController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient, :authorize_patient_access

  before_action :find_patient_case, only: [
    :edit, :show, :update, :open, :discharge,
    :archive, :unarchive
  ]

  before_action :prevent_editing_on_archived, only: [
    :edit, :update, :open, :discharge
  ]

  def index
    authorize! :read, PatientCase

    @patient_cases = @patient.patient_cases
      .includes(:case_type, :practitioner)
      .not_archived
      .order(status: :desc, created_at: :desc)
      .page(params[:page])
  end

  def new
    authorize! :create, PatientCase

    @patient_case = PatientCase.new(patient_id: params[:patient_id])
  end

  def create
    authorize! :create, PatientCase

    @patient_case = PatientCase.new case_params

    respond_to do |format|
      format.html do
        if @patient_case.save
          redirect_to patient_case_url(@patient, @patient_case),
                      notice: 'The case was successfully created.'
        else
          flash.now[:alert] = 'Failed to create case. Please check for form errors.'
          render :new
        end
      end
    end
  end

  def edit
    authorize! :update, PatientCase
  end

  def show
    authorize! :read, PatientCase

    @case_associates = [];
    @patient_case.invoices.each do |invoice|
      @case_associates << {
        id: invoice.id,
        object: invoice,
        link: invoice_path(invoice),
        created_at: invoice.created_at
      }
    end

    @patient_case.attachments.each do |attachment|
      @case_associates << {
        object: attachment,
        id: attachment.id,
        link: patient_attachment_path(attachment.patient, attachment),
        created_at: attachment.created_at
      }
    end

    @patient_case.appointments.each do |appt|
      @case_associates << {
        object: appt,
        id: appt.id,
        link: appointment_path(appt),
        created_at: appt.created_at
      }
    end

    @patient_case.treatment_notes.each do |treatment|
      @case_associates << {
        id: treatment.id,
        object: treatment,
        link: patient_treatment_note_path(treatment.patient, treatment),
        created_at: treatment.created_at
      }
    end
    @case_associates.sort_by! { |accsociate| accsociate[:created_at] }.reverse!
  end

  def update
    authorize! :update, PatientCase

    @patient_case.assign_attributes case_params

    if @patient_case.save
      redirect_to patient_case_path(@patient, @patient_case),
                  notice: 'The case was successfully updated.'
    else
      flash.now[:alert] = 'Failed to update the case. Please check for form errors.'
      render :new
    end
  end

  def discharge
    authorize! :update, PatientCase

    @patient_case.status = PatientCase::STATUS_DISCHARGED
    @patient_case.save!(validate: false)
    flash[:notice] = 'The case status was successfully changed to Discharged.'

    redirect_back fallback_location: patient_case_path(@patient, @patient_case)
  end

  def open
    authorize! :update, PatientCase

    @patient_case.status = PatientCase::STATUS_OPEN
    @patient_case.save!(validate: false)

    flash[:notice] = 'The case status was successfully changed to Open.'

    redirect_back fallback_location: patient_case_path(@patient, @patient_case)
  end

  def archive
    authorize! :update, PatientCase

    @patient_case.archived_at = Time.current
    @patient_case.save!(validate: false)

    flash[:notice] = 'The case has been successfully archived.'

    redirect_back fallback_location: patient_case_path(@patient, @patient_case)
  end

  def unarchive
    authorize! :update, PatientCase

    @patient_case.archived_at = nil
    @patient_case.save!(validate: false)

    flash[:notice] = 'The case has been successfully unarchived.'

    redirect_back fallback_location: patient_case_path(@patient, @patient_case)
  end

  private

  def case_params
    result = params.require(:patient_case).permit(
      :notes,
      :case_number,
      :invoice_total,
      :invoice_number,
      :status,
      :practitioner_id,
      :case_type_id,
      :end_date,
      :issue_date,
      :patient_id
    )
    attachments_attributes = []

    if params[:patient_case][:attachments].present?
      params[:patient_case][:attachments]&.each do |uploaded_file|
        if uploaded_file.is_a? ActionDispatch::Http::UploadedFile
          attachments_attributes << { attachment: uploaded_file, patient_id: result[:patient_id] }
        end
      end
    end

    result.merge(attachments_attributes: attachments_attributes)
  end

  def set_patient
    @patient = current_business.patients.find(params[:patient_id])
  end

  def find_patient_case
    @patient_case = @patient.patient_cases.find params[:id]
  end

  def prevent_editing_on_archived
    if @patient_case.archived?
      flash[:alert] = 'The case was archived. Please unarchive it in order to edit.'

      redirect_back fallback_location: patient_case_path(@patient, @patient_case)
    end
  end
end
