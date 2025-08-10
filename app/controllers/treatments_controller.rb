class TreatmentsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient,
                :authorize_patient_access,
                only: [
                  :new, :index, :create, :show, :edit, :update, :destroy,
                  :last_treatment_note, :print,
                  :modal_send_email, :send_email
                ]

  before_action :authorize_patient_access

  before_action :set_treatment, only: [
                  :show,
                  :edit,
                  :update,
                  :destroy,
                  :print,
                  :modal_send_email, :send_email
                ]

  def index
    @open_cases = @patient.patient_cases.includes(:case_type)
                  .where(status: PatientCase::STATUS_OPEN).
                  order(updated_at: :desc).
                  take(3)

    treatments_query = @patient.treatments.includes(:appointment, :author)

    # @TODO: improve this
    if params[:q].present?
      query_string = "%#{params[:q].to_s.downcase}%"
      treatments_query = treatments_query.where("LOWER(html_content) LIKE ? OR LOWER(name) LIKE ?", query_string, query_string)
    end

    treatments_query =
      case params[:order]
      when 'created_date'
        treatments_query.order(created_at: :desc)
      when 'appointment_date'
        treatments_query.order('appointment.start_time' => :desc)
      when 'author'
        treatments_query.order('author.full_name' => :desc)
      else
        treatments_query.order(created_at: :desc)
      end

    @treatments = treatments_query.page(params[:page])

    @upcoming_appointments = @patient.appointments.
                            where('start_time > ?', Time.current).
                            where(status: nil, cancelled_at: nil, is_completed: false).
                            order(start_time: :asc).
                            includes(:practitioner, :availability).
                            limit(3)
  end

  def show
  end

  def new
    @treatment = Treatment.new

    if params[:patient_id] &&
       current_business.patients.exists?(id: params[:patient_id])
      @treatment.patient_id = params[:patient_id]
    end

    if params[:appointment_id] &&
       current_business.appointments.exists?(id: params[:appointment_id])
      @treatment.appointment_id = params[:appointment_id]

      @treatment.treatment_template =
        @treatment.appointment.appointment_type.default_treatment_template
    end
  end

  def edit
    authorize! :edit, @treatment
  end

  def create
    @treatment = Treatment.new(create_treatment_params)
    @treatment.patient = @patient
    @treatment.status = Treatment::STATUS_DRAFT
    @treatment.author_id = current_user.id

    if @treatment.valid?
      template = @treatment.treatment_template
      @treatment.content = template.content
      @treatment.html_content = template.html_content
    end

    if @treatment.save
      if @treatment.appointment
        SubscriptionBillingService.new.bill_appointment(
          current_business,
          @treatment.appointment.id,
          SubscriptionBilling::TRIGGER_TYPE_TREATMENT_NOTE_CREATED
        )
      end

      redirect_to edit_patient_treatment_path(@patient, @treatment),
                  notice: 'Treatment note was successfully created.'
    else
      flash.now[:alert] = 'Failed to create treatment note. Please check for form errors.'
      render :new
    end
  end

  def update
    authorize! :edit, @treatment

    if @treatment.author_id.blank?
      @treatment.author_id = current_user.id
    end

    if @treatment.update(update_treatment_params)
      if @treatment.appointment
        SubscriptionBillingService.new.bill_appointment(
          current_business,
          @treatment.appointment.id,
          SubscriptionBilling::TRIGGER_TYPE_TREATMENT_NOTE_CREATED
        )
      end

      respond_to do |f|
        f.html do
          redirect_to patient_treatment_path(@patient, @treatment),
                  notice: 'Treatment note was successfully updated.'
        end
        f.json do
          render json: {
            success: true,
            message: 'Treatment note template was successfully updated.',
            treatment_template: @treatment_template
          }
        end
      end
    else
      respond_to do |f|
        f.html do
          flash.now[:alert] = 'Failed to update treatment note. Please check for form errors.'
          render :edit
        end
        f.json do
          render(
            json: {
              success: false,
              errors: @treatment_template.errors.full_messages
            },
            status: 422
          )
        end
      end
    end
  end

  def destroy
    authorize! :destroy, @treatment

    if @treatment.status == Treatment::STATUS_DRAFT
      @treatment.destroy
      redirect_to patient_treatments_url(@patient),
                  notice: 'Treatment note was successfully deleted.'
    else
      redirect_to patient_treatments_url(@patient),
                  alert: 'Can\'t delete Final treatment note.'
    end
  end

  def print
    respond_to do |format|
      format.pdf do
        download_file_name = [@patient.full_name, @treatment.name].join('__').parameterize

        render pdf: download_file_name,
              template: "pdfs/treatment_notes/single",
              show_as_html: params.key?('__debug__'),
              locals: {
                treatment: @treatment,
                patient: @patient,
                business: current_business
              },
              disable_javascript: true
      end
    end
  end

  def modal_send_email
    send_email_form = SendEmailForm.new(
      email_subject: "Treatment note from #{@current_business.name}",
      email_content: "Please find attached treatment note",
      patient: @patient,
    )

    if @patient.email.present?
      send_email_form.emails << @patient.email
    end

    render 'common/_modal_send_email',
           locals: {
             modal_title: "Send treatment note",
             send_email_url: send_email_patient_treatment_path(@patient, @treatment),
             patient: @patient,
             send_email_form: send_email_form,
             source: @treatment,
            },
            layout: false
  end

  def send_email
    form = SendEmailForm.new(
      params.permit(:email_subject, :email_content, emails: []).merge(business: current_business)
    )

    if form.valid?
      SendTreatmentNoteEmailService.new.call(@patient, @treatment, form, current_user)
      render(
        json: {
          message: 'The treatment notes has been scheduled to send.'
        }
      )
    else
      render(
        json: {
          message: "Could not send treatment note. Please check for form errors: #{form.errors.full_messages.first}."
        },
        status: 422
      )
    end
  end

  def last_treatment_note
    @treatment = @patient.treatments.where(treatment_template_id: params[:template_id])
                         .order(updated_at: :desc).first
    render json: @treatment
  end

  private

  def set_patient
    @patient = current_business.patients.find(params[:patient_id])
  end

  def set_treatment
    @treatment = Treatment.find( params[:id] )
  end

  def create_treatment_params
    params.require(:treatment).permit(
      :appointment_id,
      :treatment_template_id,
      :patient_case_id,
    )
  end

  def update_treatment_params
    params.require(:treatment).permit(
      :name,
      :appointment_id,
      :patient_case_id,
      :status,
      :content,
      :html_content
    )
  end
end
