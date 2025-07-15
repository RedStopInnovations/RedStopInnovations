module Claiming
  module Util
    class << self

      def profession_to_service_type(profession)
        {
          "Physiotherapist" => 'J',
          "Podiatrist" => 'J',
          "Occupational Therapist" => 'J',
          "Psychologist" => 'K',
          "Dietitian" => 'J',
          "Exercise Physiologist" => 'J',
          "Speech Therapist" => 'I',
          "Social Worker" => 'J',
          "Doctor" => 'O',
          "Registered Nurse" => 'F',
          "Enrolled Nurse" => 'F',
          "Support Worker" => 'F',
          "Acupuncturist" => 'J',
          "Osteopath" => 'J',
          "Chiropractor" => 'J'
        }[profession]
      end
    end
  end
end
