class UpdateWaitListService
  def call(wait_list, form)
    original_wait_list = wait_list.dup
    WaitList.transaction do
      attributes = form.attributes.symbolize_keys.slice(*%i(
        patient_id
        practitioner_id
        appointment_type_id
        profession
        date
        notes
      ))
      wait_list.assign_attributes(attributes)
      wait_list.save!(validate: false)

      if wait_list.repeat_group_uid? && form.apply_to_repeats
        WaitList.where(repeat_group_uid: wait_list.repeat_group_uid).
          where('id <> ?', wait_list.id).
          where(scheduled: false).
          where('date > ?', original_wait_list.date).
          each do |repeat|
            repeat_attrs = attributes.except(:date)
            if original_wait_list.date != wait_list.date
              diff = (wait_list.date - original_wait_list.date).to_i
              repeat_attrs[:date] = repeat.date + diff.days
            end
            repeat.assign_attributes(repeat_attrs)
            repeat.save!(validate: false)
          end
      end
    end
  end
end
