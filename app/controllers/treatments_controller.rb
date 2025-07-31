class TreatmentsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient,
                :authorize_patient_access,
                only: [
                  :new, :index, :create, :show, :edit, :update, :destroy,
                  :last_treatment_note, :export_pdf,
                  :modal_send_email, :send_email
                ]

  before_action :authorize_patient_access

  before_action :set_treatment, only: [
                  :show,
                  :edit,
                  :update,
                  :destroy,
                  :export_pdf,
                  :modal_send_email, :send_email
                ]

  def index
    @open_cases = @patient.patient_cases.includes(:case_type)
                  .where(status: PatientCase::STATUS_OPEN).
                  order(updated_at: :desc).
                  take(3)

    treatments_query = @patient.treatments
                      .includes(:appointment, :author)
    if params[:q].present?
      query_string = "%#{params[:q].to_s.downcase}%"
      treatments_query = treatments_query.where("LOWER(sections) LIKE ? OR LOWER(name) LIKE ?", query_string, query_string)
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

    # @available_treatment_templates = current_user.accessible_treatment_templates.order(name: :asc).to_a
    @available_treatment_templates = current_business.treatment_templates.order(name: :asc).to_a

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

    if @treatment.treatment_template.nil?
      @treatment.treatment_template = current_business.treatment_templates.first
    end

    if @treatment.treatment_template
      @treatment.sections = @treatment.treatment_template.template_sections
    end
  end

  def edit
    authorize! :edit, @treatment

    if @treatment.content.present?
      redirect_back fallback_location: patient_treatment_path(@patient, @treatment),
                    alert: 'This note is readonly'
      return
    end

    @available_treatment_templates = current_user.accessible_treatment_templates.order(name: :asc).to_a

    # Still show current template even if it's hidden to current user
    current_template = @treatment.treatment_template
    if current_template && @available_treatment_templates.map(&:id).exclude?(current_template.id)
      @available_treatment_templates << current_template
    end
  end

  def create
    @treatment = Treatment.new(treatment_params)
    @treatment.patient = @patient
    @treatment.author_id = current_user.id

    if @treatment.save
      ::Webhook::Worker.perform_now(@treatment.id, WebhookSubscription::TREATMENT_NOTE_CREATED)
      if @treatment.appointment
        SubscriptionBillingService.new.bill_appointment(
          current_business,
          @treatment.appointment.id,
          SubscriptionBilling::TRIGGER_TYPE_TREATMENT_NOTE_CREATED
        )
      end

      if current_business.trigger_categories.count > 0
        # Trigger::BusinessTriggersReportWorker.perform_later(current_business.id)
      end
      redirect_to patient_treatments_path(@patient),
                  notice: 'Treatment note was successfully created.'
    else
      @available_treatment_templates = current_user.accessible_treatment_templates.order(name: :asc).to_a
      flash.now[:alert] = 'Failed to create treatment note. Please check for form errors.'
      render :new
    end
  end

  def update
    authorize! :edit, @treatment

    if @treatment.content.present?
      redirect_back fallback_location: patient_treatment_path(@patient, @treatment),
                    alert: 'This note is readonly'
      return
    end

    if @treatment.author_id.blank?
      @treatment.author_id = current_user.id
    end

    if @treatment.update(treatment_params)
      if @treatment.appointment
        SubscriptionBillingService.new.bill_appointment(
          current_business,
          @treatment.appointment.id,
          SubscriptionBilling::TRIGGER_TYPE_TREATMENT_NOTE_CREATED
        )
      end

      redirect_to patient_treatments_path(@patient),
              notice: 'Treatment note was successfully updated.'
    else
      @available_treatment_templates = current_user.accessible_treatment_templates.order(name: :asc).to_a

      # Still show current template even if it's hidden to current user
      current_template = @treatment.treatment_template
      if current_template && @available_treatment_templates.map(&:id).exclude?(current_template.id)
        @available_treatment_templates << current_template
      end
      flash.now[:alert] = 'Failed to update treatment note. Please check for form errors.'
      render :edit
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

  def export_pdf
    respond_to do |format|
      format.pdf do
        download_file_name = [@patient.full_name, @treatment.name].join('__').parameterize

        render pdf: download_file_name,
              template: "pdfs/treatments/show",
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

    render 'treatments/_modal_send_email',
           locals: {
            modal_title: "Send treatment note",
            send_email_url: send_email_patient_treatment_path(@patient, @treatment),
            patient: @patient,
            send_email_form: send_email_form
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

  def treatment_params
    params.require(:treatment).permit(
      :appointment_id,
      :treatment_template_id,
      :patient_case_id,
      :status,
      sections: [
        :name,
        questions: [
          :name,
          :type,
          :required,
          answer: [:content],
          answers: [:content, :selected]
        ]
      ]
    )
  end
end
