class TreatmentsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient,
                :authorize_patient_access,
                only: [
                  :new, :index, :create, :show, :edit, :update, :destroy,
                  :last_treatment_note, :deliver, :export_pdf, :export_all,
                  :send_all_to_patient,
                  :modal_email_others,
                  :email_others,
                  :pre_send_all_to_others, :send_all_to_others
                ]

  before_action :authorize_patient_access

  before_action :set_treatment, only: [
                  :show,
                  :edit,
                  :update,
                  :destroy,
                  :deliver,
                  :export_pdf,
                  :modal_email_others,
                  :email_others
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
                  notice: 'Treatment was successfully deleted.'
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

  def deliver
    if @patient.email.present?

      com = current_business.communications.create!(
        message_type: Communication::TYPE_EMAIL,
        linked_patient_id: @patient.id,
        recipient: @patient,
        category: 'treatment_note_send',
        source: @treatment,
        direction: Communication::DIRECTION_OUTBOUND
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: @patient.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: Time.current,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      PatientMailer.treatment_note(
        @treatment, sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later

      flash[:notice] = 'The treatment note has been sent to client.'
    else
      flash[:alert] = 'The client has not an email adddress.'
    end
    redirect_to patient_treatments_path(@patient)
  end

  def last_treatment_note
    @treatment = @patient.treatments.where(treatment_template_id: params[:template_id])
                         .order(updated_at: :desc).first
    render json: @treatment
  end

  def modal_email_others
    render 'treatments/_modal_email_others',
           locals: { patient: @patient, treatment: @treatment },
           layout: false
  end

  def email_others
    form = SendOthersForm.new(
      email_others_params.merge(business: current_business)
    )

    if form.valid?
      if current_business.subscription_credit_card_added?
        contacts = current_business.contacts.where(id: form.contact_ids)

        contacts.each do |contact|
          if contact.email.present?
            com = current_business.communications.create(
              message_type: Communication::TYPE_EMAIL,
              linked_patient_id: @patient.id,
              recipient: contact,
              category: 'treatment_note_send',
              message: form.message,
              source: @treatment,
              direction: Communication::DIRECTION_OUTBOUND
            )

            com_delivery = CommunicationDelivery.create!(
              communication_id: com.id,
              recipient: contact.email,
              tracking_id: SecureRandom.base58(32),
              last_tried_at: Time.current,
              status: CommunicationDelivery::STATUS_SCHEDULED,
              provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
            )

            PatientMailer.send_treatment_note_to_contact(
              @treatment, contact, form.message, sendgrid_delivery_tracking_id: com_delivery.tracking_id
            ).deliver_later
          end
        end

        form.emails.each do |email|
          PatientMailer.send_treatment_note_to_email(@treatment, email, form.message).deliver_later
        end
      end

      flash[:notice] = 'The treatment note has been successfully sent.'
    else
      flash[:alert] = "Could not send treatment note. Error: #{form.errors.full_messages.first}."
    end

    redirect_back fallback_location: patient_treatment_url(@patient, @treatment)
  end

  def send_all_to_patient
    treatment_notes = @patient.treatments.final.order(created_at: :desc).to_a
    if treatment_notes.size == 0
      flash[:alert] = 'The client has no treatment note to send'
      redirect_to patient_treatments_path(@patient)
      return
    end

    if @patient.email.present?
      com = current_business.communications.create!(
        message_type: Communication::TYPE_EMAIL,
        linked_patient_id: @patient.id,
        recipient: @patient,
        category: 'treatment_note_send',
        source: treatment_notes.first,
        direction: Communication::DIRECTION_OUTBOUND
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: @patient.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: Time.current,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      PatientMailer.send_multiple_treatment_notes_to_patient(
        @patient, treatment_notes, sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later

      flash[:notice] = 'All treatment notes has been sent to client.'
    else
      flash[:alert] = 'The client has no email adddress.'
    end

    redirect_to patient_treatments_path(@patient)
  end

  def send_all_to_others
    treatment_notes = @patient.treatments.final.order(created_at: :desc).to_a

    if treatment_notes.size == 0
      flash[:alert] = 'The client has no treatment note to send'
    else
      if current_business.subscription_credit_card_added?
        form = SendOthersForm.new(
          email_others_params.merge(business: current_business)
        )

        if form.valid?
          SendMultipleTreatmentNotesToOtherService.new.call(@patient, treatment_notes, form)
          flash[:notice] = 'The treatment notes has been successfully sent.'
        else
          flash[:alert] = "Could not send treatment note. Error: #{form.errors.full_messages.first}."
        end
      end
    end
    redirect_to patient_treatments_path(@patient)
  end

  def pre_send_all_to_others
  end

  def export_all
    respond_to do |format|
      @treatment_notes = @patient.treatments.order(created_at: :desc).to_a
      format.pdf do
        render pdf: "treatment_notes",
              template: "pdfs/treatments/multiple",
              locals: {
                treatment_notes: @treatment_notes,
                patient: @patient,
                business: current_business
              }
      end
    end
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

  def email_others_params
    params.permit(:message, contact_ids: [], emails: [])
  end
end
