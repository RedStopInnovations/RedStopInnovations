class PatientAttachmentsController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :set_patient, :authorize_patient_access

  before_action :set_attachment, only: [
    :show, :edit, :update, :destroy, :send_to_contacts, :send_to_patient, :modal_email_others
  ]

  def index
    @attachments = @patient.attachments.page(params[:page])
  end

  def new
    @attachment = PatientAttachment.new
  end

  def create
    @errors = []
    params[:attachments].each do |index, attachment_params|
      attachment = @patient.attachments.new attachment_params.permit(:attachment, :description)
      @errors << {index: index, message: attachment.errors.full_messages.first} if attachment.invalid?
    end

    unless @errors.present?
      params[:attachments].each do |index, attachment_params|
        @patient.attachments.create attachment_params.permit(:attachment, :description)
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    if @attachment.update(attachment_params)
      redirect_to patient_attachment_url(@patient, @attachment),
                 notice: 'The attachment was updated successfully.'
    else
      flash.now[:alert] = 'Failed to update the attachment. Please check for form errors.'
      render :new
    end
  end

  def destroy
    @attachment.destroy
    redirect_back fallback_location: patient_attachments_url(@patient),
                notice: 'The attachment was deleted successfully.'
  end

  def send_to_contacts
    form = SendAttachmentToContactsForm.new(
      send_to_contacts_params.merge(business: current_business)
    )

    if form.valid?
      SendPatientAttachmentOthersService.new.call(current_business, @attachment, form)
      flash[:notice] = 'The attachment has been successfully sent.'
    else
      flash[:alert] = "Could not send attachment. Error: #{form.errors.full_messages.first}."
    end

    redirect_back fallback_location: patient_attachment_url(@patient, @attachment)
  end

  def send_to_patient
    if @patient.email.blank?
      flash[:alert] = 'The client has not email address.'
    else
      PatientAttachmentMailer.send_to_patient(@attachment).deliver_later
      flash[:notice] = 'The attachment has been successfully sent to client.'
    end

    redirect_back fallback_location: patient_attachment_url(@patient, @attachment)
  end

  def modal_email_others; end

  private

  def send_to_contacts_params
    params.permit(:message, contact_ids: [], emails: [])
  end

  def set_patient
    @patient = current_business.patients.find(params[:patient_id])
  end

  def set_attachment
    @attachment = @patient.attachments.find(params[:id])
  end

  def attachment_params
    params.require(:patient_attachment).permit(
      :attachment,
      :description
    )
  end
end
