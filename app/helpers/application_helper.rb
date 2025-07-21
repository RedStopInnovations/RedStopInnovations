module ApplicationHelper
  def page_title
    if content_for?(:title)
      sanitized_title = sanitize(content_for(:title).to_s)
      "#{ sanitized_title } | Tracksy".html_safe
    else
      'Tracksy'
    end
  end

  def canonical_url(path = nil)
    sanitized_path = path || request.path
    sanitized_path = sanitized_path.sub(Regexp.new("(^\/#{current_country.downcase}$|^\/#{current_country.downcase}\/)"), '') if current_country
    # Remove trailing slash
    sanitized_path = sanitized_path[0...-1] if sanitized_path.end_with?('/')

    "#{ ENV['BASE_URL'] }#{ sanitized_path }"
  end

  def format_money amount_in_dollar, currency = nil, delimiter = nil
    if defined?(current_business).present?
      currency = current_business&.currency
    end
    currency ||= App::DEFAULT_CURRENCY
    money = Money.from_amount amount_in_dollar.to_f, currency
    money.format(delimiter: delimiter)
  end

  def format_pricing_money amount
    country_info = ISO3166::Country.new current_country
    currency = country_info&.currency&.iso_code || App::DEFAULT_CURRENCY

    money = Money.from_amount amount.to_f, currency
    money.format
  end

  def contact_options_for_send_email(contacts)
    options = []
    contacts.each do |contact|
      options << [
        "#{contact.business_name} <#{contact.email}>", contact.id
      ]
    end

    options
  end

  def extra_emails_for_send_to_others(patient)
    options = []

    if patient.ndis_plan_manager_email.present?
      email = patient.ndis_plan_manager_email
      if EmailValidator.valid? email
        options << ["NDIS manager <#{email}>", email]
      end
    end

    if patient.hcp_manager_email.present?
      email = patient.hcp_manager_email
      if EmailValidator.valid? email
        options << ["HCP manager <#{email}>", email]
      end
    end

    if patient.hih_doctor_email.present?
      email = patient.hih_doctor_email
      if EmailValidator.valid? email
        options << ["HIH doctor <#{email}>", email]
      end
    end

    if patient.hi_manager_email.present?
      email = patient.hi_manager_email
      if EmailValidator.valid? email
        options << ["HI manager <#{email}>", email]
      end
    end

    options
  end

  def users_options_for_select(users)
    options = []

    users.each do |user|
      options << [user.full_name, user.id]
    end

    options
  end

  def business_pracititioner_options_for_select(business, options = {})
    query = business.practitioners

    if !options[:include_inactive]
      query = query.active
    end

    if options[:include_inactive]
      query = query.order('active DESC, first_name ASC')
    else
      query = query.order('first_name ASC')
    end

    practitioners = query.select(:id, :full_name, :active).to_a

    options = []

    practitioners.each do |pract|
      label = pract.full_name
      if !pract.active?
        label << " (Inactive)"
      end
      options << [pract.full_name, pract.id]
    end

    options
  end


  def pracititioner_options_for_select(business = nil)
    if business.present?
      practitioners = business.practitioners.active
    else
      practitioners = Practitioner.approved.active
    end

    practitioners = practitioners.order(full_name: :asc).select(:id, :full_name).to_a

    options = []

    practitioners.each do |pract|
      options << [pract.full_name, pract.id]
    end

    options
  end

  def appointment_type_options_for_select
    options = []
    ats = current_business.appointment_types.order(deleted_at: :desc, name: :asc).to_a
    ats.each do |type|
      display_name = type.name
      if type.deleted?
        display_name = "(Inactive) #{display_name}"
      end
      options << [display_name, type.id]
    end

    options
  end

  def subscription_plans_options_for_select(subscription_plans)
    options = []

    subscription_plans.each do |plan|
      options << [
        plan.name.titleize,
        plan.id
      ]
    end

    options
  end

  def timezone_options
    App::TIMEZONES.map do |tz|
      ["(GMT#{tz[:utc_offset]}) #{tz[:display_name]}", tz[:name]]
    end
  end

  def appointment_billing_trigger_icon(trigger_type)
    case trigger_type
    when SubscriptionBilling::TRIGGER_TYPE_COMPLETED
    '<i class="fa fa-check-square-o" title="Completed"></i>'
    when SubscriptionBilling::TRIGGER_TYPE_INVOICED
    '<i class="fa fa-credit-card" title="Invoiced"></i>'
    when SubscriptionBilling::TRIGGER_TYPE_TREATMENT_NOTE_CREATED
    '<i class="fa fa-file-text-o" title="Treatment note created"></i>'
    when SubscriptionBilling::TRIGGER_TYPE_OCCURRED
    '<i class="fa fa-clock-o" title="Finished"></i>'
    else
      ''
    end.html_safe
  end

  def resource_types_options_for_select
    [
      ['Appointment', 'Appointment'],
      ['Appointment type', 'AppointmentType'],
      ['Client', 'Patient'],
      ['Account statement', 'AccountStatement'],
      ['Contact', 'Contact'],
      ['Invoice', 'Invoice'],
      ['Payment', 'Payment'],
      ['Treatment note template', 'TreatmentTemplate'],
      ['Product', 'Product'],
      ['Billable item', 'BillableItem']
    ]
  end

  def deleted_resource_type_display_name(resource_type)
    {
      'Appointment' => 'Appointment',
      'AppointmentType' => 'Appointment type',
      'Patient' => 'Client',
      'Contact' => 'Contact',
      'AccountStatement' => 'Account statement',
      'Invoice' => 'Invoice',
      'Payment' => 'Payment',
      'TreatmentTemplate' => 'Treatment note template',
      'Product' => 'Product',
      'BillableItem' => 'Billable item'
    }[resource_type]
  end

  def incomplete_appointment_statuses_for_select
    [
      ['Client not home', Appointment::STATUS_CLIENT_NOT_HOME],
      ['Client unwell', Appointment::STATUS_CLIENT_UNWELL],
      ['Not required', Appointment::STATUS_CLIENT_NOT_REQUIRED],
      ['Late cancel by client', Appointment::STATUS_CLIENT_LATE_CANCEL_BY_CLIENT],
      ['Overtime', Appointment::STATUS_OVERTIME],
      ['Extra pay', Appointment::STATUS_EXTRA_PAY],
    ]
  end

  def mask_human_name(name)
    name.split.map do |part|
      "#{part.first}."
    end.join(' ')
  end

  def billable_items_options_for_eclaims_report(billable_items)
    options = []

    billable_items.each do |bi|
      options << ["#{bi.item_number} - #{bi.name}", bi.id]
    end

    options
  end

  def communication_category_options_for_select
    options = []
    Communication::CATEGORIES.each do |cat_id|
      next if cat_id == 'uncategorized'
      options << [t("communication.categories.#{cat_id}"),cat_id]
    end

    options
  end

  def link_to_communication_source(source)
    text, path =
    case source
    when Invoice
      ["Invoice ##{source.invoice_number}", invoice_path(source)]
    when AccountStatement
      as_source = source.source
      if as_source.is_a?(Patient)
        ["Statement ##{source.number}", patient_account_statement_path(as_source, source)]
      elsif as_source.is_a?(Contact)
        ["Statement ##{source.number}", contact_account_statement_path(as_source, source)]
      end
    when PatientLetter
      ['View letter', patient_letter_path(source.patient_id, source)]
    when PatientAttachment
      ['View attachment', patient_attachment_path(source.patient_id, source)]
    when Appointment
      ['View appointment', appointment_path(source)]
    when Treatment
      ['View treatment note', patient_treatment_path(source.patient_id, source)]
    else
    end
    text = text.presence || 'N/A'
    path = path.presence || '#'
    link_to text, path
  end

  def practitioner_document_status_icon(document)
    klass =
      if document.expiry_date?
        if document.expired?
          'fa-exclamation text-yellow'
        else
          'fa-check text-green'
        end
      else
        'fa-question'
      end
    "<i class=\"fa icon-practitioner-doc-status #{klass}\"></i>".html_safe
  end

  def pracititioner_document_types_for_select
    [
      ['Registration', PractitionerDocument::TYPE_REGISTRATION],
      ['Insurance document', PractitionerDocument::TYPE_INSURANCE],
      ['Police check', PractitionerDocument::TYPE_POLICE_CHECK],
      ['COVID vaccination certificate', PractitionerDocument::TYPE_COVID_VACCINATION_CERTIFICATE],
      ['Flu vaccination certificate', PractitionerDocument::TYPE_FLU_VACCINATION_CERTIFICATE],
      ['NDIS worker screening card', PractitionerDocument::TYPE_NDIS_WORKER_SCREENING_CARD],
      ['Contract', PractitionerDocument::TYPE_CONTRACT],
    ]
  end

  # Mask last 3 characters
  def mask_phone_number(value)
    value.gsub %r{.{3}$}, '...'
  end

  # Mask characters after '@'
  def mask_email(value)
    value.gsub %r{\@.*$}, '@...'
  end

  def link_to_reveal_contact_info(source, contact_info_value, contact_info_type, html_options = {}, &block)
    event_info = {
      type: 'rci',
      data: {
        url: request.path,
        page_title: content_for(:title),
        contact_info_type: contact_info_type,
        contact_info_value: contact_info_value
      }
    }

    title = contact_info_type.to_s.titleize
    html_options[:class] = "js-rci #{html_options[:class]}"

    case source
    when Business
      event_info[:data][:business_id]  = source.id
      event_info[:data][:source_type]  = 'Business'
      event_info[:data][:source_id]    = source.id
      event_info[:data][:source_title] = source.name
    when Practitioner
      event_info[:data][:business_id]  = source.business_id
      event_info[:data][:source_type]  = 'Practitioner'
      event_info[:data][:source_id]    = source.id
      event_info[:data][:source_title] = source.full_name
    end

    masked_contact_info_value =
      case contact_info_type
      when :phone
        mask_phone_number(contact_info_value)
      when :email
        mask_email(contact_info_value)
      end

    if html_options[:max_length] && masked_contact_info_value.length > html_options[:max_length]
      masked_contact_info_value = truncate masked_contact_info_value, length: html_options[:max_length]
    end

    link_attributes = html_options.merge(
      href: '#',
      tabindex: '0',
      title: title,
      data: {
        type: contact_info_type.to_s,
        value: Base64.encode64(contact_info_value),
        'track-event' => Base64.encode64(event_info.to_json)
      }
    )

    if block_given?
      content_tag('a', masked_contact_info_value, link_attributes) do
        yield
      end
    else
      content_tag('a', masked_contact_info_value, link_attributes)
    end
  end

  def format_travel_duration_report(seconds)
    if seconds.present? && seconds > 0
      (seconds.to_f / 3600).round(2)
    else
      '0'
    end
  end

  def format_appointment_duration_report(minutes)
    if minutes.present? && minutes > 0
      (minutes.to_f / 60).round(2)
    else
      '0'
    end
  end

  def format_travel_distance_report(meters)
    if meters.present? && meters > 0
      (meters.to_f / 1000).round(2)
    else
      '0'
    end
  end

  def calculate_tax_amount_on_payment(payment)
    amount = 0

    payment.payment_allocations.each do |pa|
      invoice = pa.invoice
      if invoice
        tax_amount = invoice.amount - invoice.amount_ex_tax
        if tax_amount > 0
          tax_percent = (tax_amount / invoice.amount) * 100
          amount += pa.amount * tax_percent / 100
        end
      end
    end

    amount
  end

  def all_professions_options_for_filter
    options = [ ['All specialists', nil] ]

    Practitioner::PROFESSIONS.each do |profession|
      options << [profession, profession]
    end

    options
  end

  def get_communication_templates_explains
    Rails.cache.fetch('communication_templates_explains', expires_in: 30.days) do
      map = {}

      YAML.load_file(
        Rails.root.join('db/seeds/default_communication_templates.yml')
      ).each do |template_attrs|
        map[template_attrs['template_id']] = template_attrs['explanation']
      end

      map
    end
  end

  def build_data_for_button_trigger_sms(number, body)
    Base64.encode64({
      number: number,
      body: body
    }.to_json)
  end

  def outstanding_invoice_reminder_sms_body(invoice, business = nil)
    if !business
      business = invoice.business
    end

    lines = [
      "Hi #{invoice.patient.full_name}",
      "I'm sending a friendly reminder that invoice #{invoice.invoice_number} with #{business.name} is overdue. We appreciate your prompt payment. Please get in touch with us ASAP if you have any questions.",
      "",
      "Outstanding amount: #{format_money(invoice.outstanding)}"
    ]

    if business.bank_account_name.present? && business.bank_branch_number.present? && business.bank_account_number.present?
      lines += [
        "Name: #{business.bank_account_name}",
        "BSB: #{business.bank_branch_number}",
        "Account: #{business.bank_account_number}"
      ]
    end

    lines += [
      "",
      "Kind regards,",
      "#{current_user.full_name}"
    ]

    lines.join("\n")
  end

  def patient_without_upcoming_appointment_follow_up_sms_body(patient, last_appointment)
    lines = [
      "Hi #{patient.full_name},",
      "",
      "How are you going after your appointment with #{last_appointment.practitioner.full_name} on #{last_appointment.start_time_in_practitioner_timezone.strftime('%d %b')}? I noticed you don't have future appointments scheduled. Do you require any extra assistance?",
      "",
      "Kind regards",
      "#{current_business.name}."
    ]

    lines.join("\n")
  end

  def patient_follow_up_reminder_email_to_practitioner_body(patient, practitioner)
    lines = [
      "Hi #{practitioner.full_name},",
      "",
      "The following clients have yet to book a repeat appointment. Please contact them to schedule another appointment. If no further appointments are required, could you please archive them via the button on their client profile?",
      "",

      "#{patient.full_name}",
      "DOB: #{patient.dob&.strftime(I18n.t('date.dob'))}",
      "Address: #{patient.short_address}",
      "Phone: #{patient.phone.presence || 'N/A'}",
      "Mobile: #{patient.mobile.presence || 'N/A' }",
      "Email: #{patient.email.presence || 'N/A'}",
      "",
      "Kind regards,",
      "#{current_business.name}."
    ]

    lines.join("\n")
  end

  def humanize_period(period)
    {
      'ALL' => 'All the time',
      '6m' => '6 months',
      '9m' => '9 months',
      '1y' => '1 year',
      '2y' => '2 years',
      '3y' => '3 years',
    }[period]
  end

  def communication_delivery_status_text_color_class(status)
    {
      CommunicationDelivery::STATUS_ERROR => 'text-danger',
      CommunicationDelivery::STATUS_DELIVERED => 'text-success'
    }[status]
  end

  def practitioner_group_options_for_select(business)
    options = []

    business.groups.order(name: :asc).to_a.each do |group|
      options << [group.name, group.id]
    end

    options
  end

  def chat_on_whatsapp_url(mobile, country_code)
    "https://wa.me/" << TelephoneNumber.parse(mobile, country_code).international_number(formatted: false)
  end

  def subscription_invoice_status_badge_class(status)
    backgrounds = {
      "pending" => "bg-yellow",
      "on_hold" => "bg-red",
      "paid" => "bg-green"
    }

    backgrounds[status]
  end

  def calculate_age(dob)
    diff_days = (Date.today - dob).to_i
    (diff_days.to_f / 365).round
  end

  def default_referral_reject_reason_options
    [
      'Inappropriate',
      'Duplicate',
      'Out of service area',
      'Unable to accept'
    ]
  end

  def get_referral_reject_reason_options_for_business(business)
    if ReferralRejectReason.where(business_id: business.id).exists?
      ReferralRejectReason.where(business_id: business.id).order(reason: :asc).pluck(:reason)
    else
      default_referral_reject_reason_options
    end
  end

  def invoice_billing_type_options_for_select
    [
      ['Appointments', Appointment.name],
      ['Tasks', Task.name],
      ['Not specified', 'NOT_SPECIFIED'],
    ]
  end
end
