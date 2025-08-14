class CreateBusinessDefaultDataService
  attr_reader :business

  def call(business)
    @business = business
    practitioner_ids = business.practitioners.pluck(:id)
    # Default billable items
    initial_item = business.billable_items.new(
      name: 'Initial consultation',
      description: 'The first home visit consultation',
      item_number: '500',
      price: 130,
      practitioner_ids: practitioner_ids,
    )
    initial_item.save!(validate: false)
    subsequent_item = business.billable_items.new(
      name: 'Subsequent consultation',
      description: 'A subsequent home visit consultation',
      item_number: '505',
      price: 100,
      practitioner_ids: practitioner_ids,
    )
    subsequent_item.save!(validate: false)

    # Default appointment types
    business.appointment_types.create!(
      name: 'Initial consultation',
      description: 'The first home visit consultation',
      duration: 60,
      billable_item_ids: [initial_item.id],
      availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID,
      practitioner_ids: practitioner_ids,
    )
    business.appointment_types.create!(
      name: 'Subsequent consultation',
      description: 'A subsequent home visit consultation',
      duration: 45,
      billable_item_ids: [subsequent_item.id],
      availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID,
      practitioner_ids: practitioner_ids,
    )

    create_default_letter_templates
    create_default_communication_templates
    create_notification_type_settings
    create_default_invoice_settings
    create_default_availability_subtypes
    create_default_general_settings
  end

  private

  def create_default_letter_templates
    YAML.load_file(
      Rails.root.join('db/seeds', 'default_letter_templates.yml')
    ).each do |template_attrs|
      business.letter_templates.create!(template_attrs)
    end
  end

  def create_default_communication_templates
    YAML.load_file(
      Rails.root.join('db/seeds', 'default_communication_templates.yml')
    ).each do |raw_template_attrs|

      business.communication_templates.create!(raw_template_attrs.slice(
        'name', 'template_id', 'email_subject', 'content', 'settings'
      ))
    end
  end

  def create_notification_type_settings
    NotificationType.all.each do |nt|
      NotificationTypeSetting.create!(
        business_id: business.id,
        notification_type_id: nt.id,
        template: nt.default_template,
        config: nt.default_config,
        enabled_delivery_methods: [
          # Only enable email by default
          NotificationType::DELIVERY_METHOD__EMAIL
        ],
        enabled: true
      )
    end
  end

  def create_default_invoice_settings
    InvoiceSetting.new(
      business_id: business.id,
      starting_invoice_number: 1
    ).save!(validate: false)
  end

  def create_default_availability_subtypes
    App::DEFAULT_AVAILABILITY_SUBTYPES.each do |subtype_name|
      AvailabilitySubtype.create!(
        business_id: business.id,
        name: subtype_name
      )
    end
  end

  def create_default_general_settings
    BusinessSetting.create!(business_id: business.id)
  end
end
