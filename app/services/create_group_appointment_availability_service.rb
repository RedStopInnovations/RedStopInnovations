class CreateGroupAppointmentAvailabilityService
  attr_reader :business, :form_request

  # @param ::Business business
  # @param CreateGroupAppointmentAvailabilityForm form_request
  def call(business, form_request)
    @business = business
    @form_request = form_request
    result = OpenStruct.new

    avail = build_availability
    avail.business_id = business.id

    begin
      Availability.transaction do
        avail.save!(validate: false)

        AvailabilityCachedStats.new.update(avail)

        result.success = true
        result.availability = avail
      end

    rescue => error
      result.success = false
    end

    if avail.persisted?
      SyncAvailabilityToGoogleCalendarWorker.perform_async(avail.id)
    end

    result
  end

  private

  def build_availability
    avail = Availability.new(
      form_request.attributes.slice(
        :practitioner_id,
        :start_time,
        :end_time,
        :address1,
        :city,
        :state,
        :postcode,
        :country,
        :max_appointment
      )
    )

    avail.assign_attributes(
      availability_type_id: AvailabilityType::TYPE_GROUP_APPOINTMENT_ID,
      group_appointment_type_id: form_request.appointment_type_id,
      contact_id: form_request.contact_id.presence
    )

    avail.description = form_request.description.presence

    avail
  end
end
