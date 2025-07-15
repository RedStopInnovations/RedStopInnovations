class CreateNonBillableAvailabilityService
  REPEAT_TYPE_DAILY = 'daily'
  REPEAT_TYPE_WEEKLY = 'weekly'
  REPEAT_TYPE_MONTHLY = 'monthly'

  attr_reader :business, :form_request

  # @param ::Business business
  # @param CreateNonBillableAvailabilityForm form_request
  def call(business, form_request)
    @business = business
    @form_request = form_request
    result = OpenStruct.new

    avail = build_availability
    avail.business_id = business.id
    recurring = form_request.repeat?

    Availability.transaction do
      if recurring
        avail_recurring = create_availability_recurring(avail)
        avail.recurring_id = avail_recurring.id
      end

      avail.save!(validate: false)

      AvailabilityCachedStats.new.update(avail)

      if recurring
        create_repeats(avail)
      end
      result.success = true
      result.availability = avail
    end

    if avail.persisted?
      SyncAvailabilityToGoogleCalendarWorker.perform_async(avail.id)
      if recurring
        repeat_avail_ids = Availability.where(
            recurring_id: avail.recurring_id,
          ).
          where('id <> ?', avail.id).
          pluck(:id)

        repeat_avail_ids.each do |repeat_avail_id|
          SyncAvailabilityToGoogleCalendarWorker.perform_async(repeat_avail_id)
        end
      end
    end

    # TODO: catch transaction error -> result.success = false

    result
  end

  private

  def build_availability
    avail = Availability.new(
      form_request.attributes.slice(
        :name,
        :availability_subtype_id,
        :practitioner_id,
        :contact_id,
        :start_time,
        :end_time
      )
    )

    [
      :description,
      :address1,
      :city,
      :state,
      :postcode,
      :country
    ].each do |text_attr|
      avail[text_attr] = form_request.send(text_attr).presence
    end

    avail.assign_attributes(
      availability_type_id: AvailabilityType::TYPE_NON_BILLABLE_ID
    )

    avail
  end

  def create_availability_recurring(source_avail)
    AvailabilityRecurring.create!(
      practitioner_id: source_avail.practitioner_id,
      repeat_type: form_request.repeat_type,
      repeat_total: form_request.repeat_total,
      repeat_interval: form_request.repeat_interval
    )
  end

  def create_repeats(source_avail)
    last_repeat = source_avail
    form_request.repeat_total.times do |time|
      repeat_avail = Availability.new(
        source_avail.attributes.symbolize_keys.slice(
          :name,
          :description,
          :practitioner_id,
          :availability_subtype_id,
          :contact_id,
          :address1,
          :city,
          :state,
          :postcode,
          :country
        )
      )

      repeat_avail.business_id = business.id
      repeat_avail.availability_type_id = AvailabilityType::TYPE_NON_BILLABLE_ID
      repeat_avail.start_time, repeat_avail.end_time =
        case form_request.repeat_type
        when REPEAT_TYPE_DAILY
          [
            last_repeat.start_time.advance(days: form_request.repeat_interval),
            last_repeat.end_time.advance(days: form_request.repeat_interval)
          ]
        when REPEAT_TYPE_WEEKLY
          [
            last_repeat.start_time.advance(weeks: form_request.repeat_interval),
            last_repeat.end_time.advance(weeks: form_request.repeat_interval)
          ]
        when REPEAT_TYPE_MONTHLY
          [
            last_repeat.start_time.advance(months: form_request.repeat_interval),
            last_repeat.end_time.advance(months: form_request.repeat_interval)
          ]
        else
          raise "Uknown repeat type: #{form_request.repeat_type}"
        end

      repeat_avail.latitude     = source_avail.latitude
      repeat_avail.longitude    = source_avail.longitude
      repeat_avail.recurring_id = source_avail.recurring_id
      repeat_avail.save!(validate: false)

      AvailabilityCachedStats.new.update(repeat_avail)

      last_repeat = repeat_avail
    end
  end
end
