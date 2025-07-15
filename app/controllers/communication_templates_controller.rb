class CommunicationTemplatesController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, CommunicationTemplate
  end

  before_action :set_communication_template, only: [:edit, :update, :preview]

  def index
    @communication_templates = current_business.communication_templates.order(id: :asc)
  end

  def edit
  end

  def update
    settings = prepare_template_settings_for_store(@communication_template)
    settings_validate_errors = validate_template_settings(@communication_template, settings)

    @communication_template.assign_attributes(update_params)
    @communication_template.settings = settings

    if @communication_template.valid? && settings_validate_errors.empty?
      @communication_template.save!(validate: false)

      redirect_to edit_communication_template_url(@communication_template),
                  notice: 'The settings successfuly updated'
    else

      unless settings_validate_errors.empty?
        @communication_template.errors.add(:settings, settings_validate_errors)
      end

      flash.now[:alert] = 'Failed to update settings. Please check for form errors.'
      render :edit
    end
  end

  def preview
    business = current_business
    practitioner = current_user.practitioner
    patient = business.patients.first
    appointment = business.appointments.first

    result = Letter::Renderer.new(patient, @communication_template).render([
      business,
      practitioner,
      appointment
    ].compact, hightlight_missing: true)

    render json: { preview: result }
  end

  private

  def update_params
    if @communication_template.is_email_template?
      params.require(:communication_template).permit(
        :email_subject,
        :enabled,
        :content,
        attachments_attributes: [
          :id, :attachment, :_destroy
        ]
      )
    elsif @communication_template.is_sms_template?
      params.require(:communication_template).permit(
        :enabled,
        :content
      )
    end
  end

  def validate_template_settings(template, settings_h)
    errors = []

    case template.template_id
    when CommunicationTemplate::TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER
      unless settings_h[:outstanding_days].present? &&
        settings_h[:outstanding_days].is_a?(Integer) &&
        settings_h[:outstanding_days] >= 3 &&
        settings_h[:outstanding_days] <= 180
        errors << 'The minimum outstanding days must be a number of days between 3 and 180'
      end

      if settings_h[:repeat]
        unless settings_h[:repeat_interval_days].present? &&
          settings_h[:repeat_interval_days].is_a?(Integer) &&
          settings_h[:repeat_interval_days] >= 3 &&
          settings_h[:repeat_interval_days] <= 90
          errors << 'The repeat interval must be a number of days between 3 and 90'
        end

        unless settings_h[:repeat_occurences].present? &&
          settings_h[:repeat_occurences].is_a?(Integer) &&
          settings_h[:repeat_occurences] >= 1 &&
          settings_h[:repeat_occurences] <= 10
          errors << 'The maximum repeat occurences must be an integer number between 1 and 10'
        end
      end
    when CommunicationTemplate::TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE
      # Validate selected billable items are belong to current business
      if settings_h[:billable_item_ids].present?
        if current_business.billable_items.where(id: settings_h[:billable_item_ids]).count != settings_h[:billable_item_ids].count
          errors << 'Some selected billable items are not existing'
        end
      end
    end

    errors
  end

  def prepare_template_settings_for_store(template)
    settings_h = {}

    case template.template_id
    when CommunicationTemplate::TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER
      given_settings_h = params.require(:communication_template).permit(
        settings: [
          :outstanding_days,
          :repeat,
          :repeat_interval_days,
          :repeat_occurences
        ]
      ).to_h[:settings]

      if given_settings_h[:outstanding_days].present?
        settings_h[:outstanding_days] = given_settings_h[:outstanding_days].to_i
      end

      if given_settings_h.key?(:repeat)
        if given_settings_h[:repeat] == '1'
          settings_h[:repeat] = true

          if given_settings_h[:repeat_interval_days].present?
            settings_h[:repeat_interval_days] = given_settings_h[:repeat_interval_days].to_i
          end

          if given_settings_h[:repeat_occurences].present?
            settings_h[:repeat_occurences] = given_settings_h[:repeat_occurences].to_i
          end
        else
          settings_h[:repeat] = false
        end
      else
        # Default is not repeat
        settings_h[:repeat] = false
      end
    when CommunicationTemplate::TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE
      given_settings_h = params.require(:communication_template).permit(
        settings: [
          billable_item_ids: []
        ]
      ).to_h[:settings] || {}

      if given_settings_h[:billable_item_ids].present? && given_settings_h[:billable_item_ids].is_a?(Array)
        settings_h[:billable_item_ids] = given_settings_h[:billable_item_ids].map(&:to_i)
      end
    end

    settings_h
  end

  def set_communication_template
    @communication_template = current_business.communication_templates.find(params[:id])
  end
end
