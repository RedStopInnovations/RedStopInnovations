# @TODO: refactor and write tests
class BookingService
  class Exception < StandardError; end

  # @param booking_form BookingForm
  def call(booking_form)
    result = OpenStruct.new(success: true)
    @availability = Availability.find(booking_form.availability_id)
    @booking_form = booking_form
    @practitioner = @availability.practitioner
    @business = @practitioner.business
    @appointment_type = AppointmentType.find(booking_form.appointment_type_id)

    appointment = nil
    stripe_charge = nil

    build_patient

    if @availability.home_visit?
      check_patient_location
      ensure_availability_service_radius
    end

    begin
      ActiveRecord::Base.transaction do
        save_patient_info
        grant_patient_access_to_pracitioner
        appointment = create_appointment

        if @availability.home_visit? && @booking_form.bookings_answers.present?
          store_bookings_answers(appointment)
        end
      end
    rescue => e
      raise e
    end

    if appointment
      result.success = true
      result.appointment = appointment
      patient = appointment.patient

      PractitionerMailer.new_online_booking(appointment).deliver_later

      if patient.email?
        AppointmentMailer.booking_confirmation(appointment.id).deliver_later
      end

      SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__BOOKED_ONLINE)

      if appointment.home_visit? || appointment.facility?
        CalculateArrivalTimesJob.perform_later(appointment.availability_id)
      end

      if appointment.home_visit? && appointment.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(appointment.availability_id)
      end

      Webhook::Worker.perform_later(
        appointment.id,
        'appointment_created'
      )

    else
      result.success = false
    end

    result
  end

  private

  def save_patient_info
    if @patient.new_record?
      @patient.business_id = @business.id
    end

    @patient.save!
  end

  def create_appointment
    appt = Appointment.new(
      practitioner: @availability.practitioner,
      availability: @availability,
      patient: @patient,
      appointment_type: @appointment_type,
      booked_online: true,
      notes: @booking_form.notes.presence.to_s
    )

    if @availability.home_visit? || @availability.facility?
      appt.assign_attributes(
        start_time: @availability.start_time,
        end_time: @availability.end_time,
        order: @availability.appointments.maximum(:order).to_i + 1
      )
    else
      raise NotImplementedError
    end

    appt.save!

    appt
  end

  def patient_info
    @patient_info ||= @booking_form.attributes.slice(
      *%i(first_name last_name email mobile dob address1 address2 city state postcode country)
    ).tap do |info|
      info.each_pair do |attr, val|
        if %i(first_name last_name email mobile address1).include?(attr)
          info[attr] = val.to_s.strip.presence
        end
      end
    end
  end

  def build_patient
    patient = find_exists_patient_match
    patient = Patient.new(patient_info) if patient.nil?
    patient.assign_attributes(parse_full_address)
    patient.accepted_privacy_policy = true
    @patient = patient
  end

  # OPTIMIZE: we need to review this.
  # Im not sure what to do if the matched patient has difference address with
  # the submitted address. Patient location is important as we have service radius restriction.
  # Matching criterias: name, mobile
  def find_exists_patient_match
    return nil
    matched_patient = nil

    potential_patients = @business.patients.
      where(
        'LOWER(first_name) = ? AND LOWER(last_name) = ?',
        patient_info[:first_name].downcase,
        patient_info[:last_name].downcase
      ).load

    if potential_patients.size > 0
      given_dob_date = Date.parse(patient_info[:dob]).strftime('Y-m-d') rescue nil
      matched_patient = potential_patients.find do |patient|
        patient.dob.is_a?(Date) && patient.dob.strftime('Y-m-d') == given_dob_date
      end
    end

    matched_patient
  end

  def check_patient_location
    @patient.geocode
    if @patient.latitude.blank? || @patient.longitude.blank?
      raise Exception, 'Sorry, your address is not recognized.'
    end
  end

  def ensure_availability_service_radius
    distance = Geocoder::Calculations.distance_between(
      @patient.to_coordinates,
      @availability.to_coordinates
    ).round
    if distance > @availability.service_radius
      raise Exception, 'Sorry, your location is out of service radius.'
    end
  end

  # TODO: use value object
  def parse_full_address
    geocode_result = Geocoder.search(@booking_form.full_address)[0]
    address_attrs = {
    }
    if geocode_result
      geocode_result.data['address_components'].each do |addr_component|
        if addr_component['types'].include?('subpremise')
          address_attrs[:address1] = addr_component['short_name']
        end
        if addr_component['types'].include?('street_number')
          address_attrs[:address1] = [
            address_attrs[:address1], addr_component['short_name']
        ].compact.join('/')
        end
        if addr_component['types'].include?('route')
          address_attrs[:address1] = [
            address_attrs[:address1], addr_component['short_name']
        ].compact.join(' ')
        end
        if addr_component['types'].include?('locality')
          address_attrs[:city] = addr_component['short_name']
        end
        if addr_component['types'].include?('administrative_area_level_1')
          address_attrs[:state] = addr_component['short_name']
        end
        if addr_component['types'].include?('postal_code')
          address_attrs[:postcode] = addr_component['short_name']
        end
        if addr_component['types'].include?('country')
          address_attrs[:country] = addr_component['short_name']
        end
      end

      location = geocode_result.data['geometry']['location']
      address_attrs[:latitude] = location['lat']
      address_attrs[:longitude] = location['lng']
    end

    address_attrs
  end

  def grant_patient_access_to_pracitioner
    PatientAccess.create!(
      user_id: @practitioner.user_id,
      patient_id: @patient.id
    )
  end

  def store_bookings_answers(appointment)
    @booking_form.bookings_answers.each do |answer|
      question = @business.bookings_questions.find_by(id: answer.question_id)
      if question
        ba = AppointmentBookingsAnswer.new(
          appointment_id: appointment.id,
          question_id: answer.question_id,
          question_title: question.title
        )

        case question.type
        when 'Text'
          ba.answer = {
            content: answer.answer.content
          }
        when 'Checkboxes', 'Radiobuttons'
          answers = []
          answer.answers.each do |anws|
            answers << {
              content: anws.content
            }
          end

          ba.answers = answers
        end

        ba.save(validate: false)
      end
    end
  end

  def create_stripe_charge(invoice)
    Stripe::Charge.create(
      {
        amount: (invoice.amount * 100).to_i,
        currency: @business.currency,
        source: @booking_form.stripe_token,
        description: "Payment for appointment #{ @availability.start_time_in_practitioner_timezone.strftime(I18n.t('date.common')) }",
        metadata: build_stripe_charge_metadata
      },
      stripe_account: @business.stripe_account.account_id
    )
  end

  def build_payment_from_stripe_charge(stripe_charge)
    Payment.new(
      business: @business,
      payment_date: Date.today,
      stripe_charge_id: stripe_charge.id,
      stripe_charge_amount: stripe_charge.amount.to_f / 100,
      editable: false # We dont allow edit payment made via Stripe or Medipass
    )
  end

  def build_stripe_charge_metadata
    {
      Patient: @patient.full_name,
      Practitioner: @practitioner.full_name
    }
  end

  def build_invoice
    total_amount = 0
    total_amount_ex_tax = 0

    invoice = Invoice.new(
      issue_date: Date.today,
      business_id: @business.id
    )

    billable_items = @appointment_type.billable_items

    if billable_items.empty?
      raise 'No billable items to create invoice'
    end

    billable_items.each do |billable_item|
      invoice_item = invoice.items.new

      # Remember the tax as the time the item is created
      invoice_item.quantity = 1
      invoice_item.unit_price = billable_item.price

      item_amount_ex_tax = invoice_item.quantity * invoice_item.unit_price
      invoice_item.unit_name = billable_item.name
      invoice_item.tax_name = billable_item.tax_name
      invoice_item.tax_rate = billable_item.tax_rate

      item_tax_amount =
        if billable_item.tax_rate
          billable_item.tax_rate * item_amount_ex_tax / 100
        else
          0
        end

      item_total_amount = item_amount_ex_tax + item_tax_amount

      invoice_item.amount = item_total_amount

      total_amount_ex_tax += item_amount_ex_tax
      total_amount += item_total_amount

    end

    invoice.assign_attributes(
      amount: total_amount,
      amount_ex_tax: total_amount_ex_tax,
      outstanding: 0
    )

    invoice
  end

  def generate_invoice_number
    max_number = @business.invoices.with_deleted.maximum "CAST(invoice_number AS integer)"
    max_number = 0 if max_number.nil?

    invoice_start_number = @business.invoice_setting.try(:starting_invoice_number)
    invoice_start_number = 1 if invoice_start_number.nil?

    number =
      if invoice_start_number > max_number
        invoice_start_number
      else
        max_number + 1
      end

    # Invoice numbers has at least 5 characters with leading zeros
    number.to_s.rjust 5, '0'
  end
end
