class PatientLettersController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient
  before_action :authorize_patient_access
  before_action :set_patient_letter, only: [
    :show, :edit, :update, :destroy,
    :send_patient, :send_others
  ]

  # Authorize patient letters access
  before_action do
    authorize! :manage, PatientLetter
  end

  def index
    @patient_letters = @patient.letters.includes(:author).page(params[:pages])
  end

  def show
    respond_to do |f|
      f.html
      f.pdf do
        download_file_name = [@patient.full_name, @patient_letter.description].join('__').parameterize
        render(
          pdf: download_file_name,
          template: 'pdfs/patient_letter',
          locals: {
            patient_letter: @patient_letter
          }
        )
      end
    end
  end

  def new
    @patient_letter = PatientLetter.new

    # Prefill content for letter if the letter template is specified in params
    if params.has_key?(:letter_template_id) &&
      (template = current_business.letter_templates.find_by(id: params[:letter_template_id]))

      @patient_letter.letter_template = template
      @patient_letter.content = Letter::Renderer.new(@patient, template).render([
        current_business,
        current_user.practitioner
      ].compact, hightlight_missing: true).content
    end
  end

  def edit
  end

  def create
    @patient_letter = @patient.letters.new(patient_letter_params)
    @patient_letter.business = current_business
    @patient_letter.author = current_user.practitioner

    if @patient_letter.save
      redirect_to patient_letter_url(@patient, @patient_letter),
                  notice: 'The letter was successfully created.'
    else
      render :new
    end
  end

  def update
    if @patient_letter.update(patient_letter_params)
      redirect_to patient_letter_url(@patient, @patient_letter),
                  notice: 'The letter was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @patient_letter.destroy
    redirect_to patient_letters_url,
                notice: 'The letter was successfully destroyed.'
  end

  def send_patient
    form = SendLetterToPatientForm.new(send_patient_params)

    if form.valid?
      if current_business.subscription_credit_card_added?
        SendLetterToPatientService.new.call(@patient_letter, current_user, form)
      end
      head :no_content
    else
      render json: {
              errors: form.errors.full_messages,
              message: 'Please check for form errors.'
             },
             status: :unprocessable_entity
    end
  end

  def send_others
    form = SendLetterToOthersForm.new(
      send_others_params.merge(business: current_business)
    )

    if form.valid?
      if current_business.subscription_credit_card_added?
        SendLetterToOthersService.new.call(@patient_letter, current_user, form)
      end
      head :no_content
    else
      render json: {
              errors: form.errors.full_messages,
              message: 'Please check for form errors.'
             },
             status: :unprocessable_entity
    end
  end

  private

  def set_patient
    @patient = current_business.patients.find(params[:patient_id])
  end

  def set_patient_letter
    @patient_letter = @patient.letters.find(params[:id])
  end

  def patient_letter_params
    params.require(:patient_letter).permit(
      :letter_template_id,
      :description,
      :content
    )
  end

  def send_patient_params
    params.permit(
      :send_format,
      :email_subject,
      :email_content
    )
  end

  def send_others_params
    params.permit(
      :send_format,
      :email_subject,
      :email_content,
      contact_ids: [],
      emails: []
    )
  end
end
