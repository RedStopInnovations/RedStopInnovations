class CreateWaitListService
  attr_reader :business, :form_request

  # @param business Business
  # @param form_request CreateWaitListForm
  def call(business, form_request)
    @business = business
    @form_request = form_request
    result = OpenStruct.new(success: true)

    wait_list = build_wait_list

    ActiveRecord::Base.transaction do
      if repeat?
        repeat_group_uid = SecureRandom.hex(10)
        wait_list.repeat_group_uid = repeat_group_uid
      end

      wait_list.save!(validate: false)

      if repeat?
        create_repeats(wait_list)
      end

      result.wait_list = wait_list
    end

    result
  end

  private

  def repeat?
    form_request.repeat_type.present?
  end

  def build_wait_list
    wait_list = WaitList.new(business_id: business.id)

    massive_attributes = form_request.attributes.slice(
      :patient_id,
      :practitioner_id,
      :appointment_type_id,
      :profession,
      :date,
      :notes
    )

    massive_attributes.each_pair do |k, v|
      if v.blank?
        massive_attributes[k] = v.presence
      end
    end

    wait_list.assign_attributes massive_attributes

    wait_list
  end

  def create_repeats(source_wait_list)
    repeat_step =
      case form_request.repeat_type
      when 'Daily'
        1 * form_request.repeat_frequency
      when 'Weekly'
        7 * form_request.repeat_frequency
      else
        raise NotImplementedError, "Unknown repeat type '#{form_request.repeat_type}'"
      end

    # Although we already validate the repeats total maximum by 20,
    # I need to verify at this point, any developer mistakes will let users
    # create millions of records.
    raise 'Something really wrong!' if form_request.repeats_total > 50

    if form_request.repeat_frequency > 0 && form_request.repeats_total > 0
      form_request.repeats_total.times do |i|
        repeat_entry = source_wait_list.dup
        repeat_entry.repeat_group_uid = source_wait_list.repeat_group_uid
        repeat_entry.date = source_wait_list.date + ((i + 1) * repeat_step)
        repeat_entry.save!(validate: false)
      end
    end
  end
end
