module TreatmentNotesHelper
  def patient_case_options_for_treatment_note(patient_cases)
    options = []
    options << ['-- Select one --', nil]
    patient_cases.each do |patient_case|
      options << [
        "#{patient_case.case_number} - #{patient_case.status}",
        patient_case.id
      ]
    end
    options
  end

  def appointment_options_for_treatment_note(appointments)
    options = []
    options << ['-- Select one --', nil]
    appointments.each do |appt|
      options << [
        "##{appt.id} | #{appt.start_time.try(:strftime, I18n.t('date.common'))} | Practitioner: #{appt.practitioner.full_name}",
        appt.id
      ]
    end

    options
  end
end
