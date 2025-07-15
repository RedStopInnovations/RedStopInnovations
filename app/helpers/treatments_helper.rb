module TreatmentsHelper
  def patient_case_options_for_treatment(patient_cases)
    options = []
    options << ['-- Select one --', nil]
    patient_cases.each do |patient_case|
      options << [
        "#{patient_case.case_type.try(:title)} - #{patient_case.status}",
        patient_case.id
      ]
    end
    options
  end

  def appointment_options_for_treatment(appointments)
    options = []
    options << ['-- Select one --', nil]
    appointments.each do |appt|
      options << [
        "##{appt.id} | #{appt.start_time.try(:strftime, I18n.t('datetime.common'))} | Practitioner: #{appt.practitioner.full_name}",
        appt.id
      ]
    end

    options
  end
end
