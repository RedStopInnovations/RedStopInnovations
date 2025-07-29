class BookingForm < BaseForm
  class BookingsAnswer
    class Answer
      include Virtus.model
      include ActiveModel::Model
      attribute :content
    end

    include Virtus.model
    include ActiveModel::Model
    attribute :question_id, Integer
    attribute :answer, Answer
    attribute :answers, Array[Answer]
  end

  attribute :availability_id, Integer
  attribute :appointment_type_id, Integer
  attribute :first_name, String
  attribute :last_name, String
  attribute :dob, String
  attribute :email, String
  attribute :mobile, String
  attribute :full_address, String
  attribute :notes, String
  attribute :privacy_policy, String
  attribute :bookings_answers, Array[BookingsAnswer]

  validates_presence_of :availability_id, :appointment_type_id
  validates_presence_of :first_name,
                        :last_name,
                        :mobile,
                        :dob
  validates :full_address, presence: true
  validates :email, email: :true, allow_blank: true, allow_nil: true

  validates :notes,
            length: { maximum: 300 },
            allow_blank: true,
            allow_nil: true

  validate if: :home_visit_appointment? do
    if availability
      business = availability.business
      # Validate bookings questions
      questions = ::BookingsQuestion.not_deleted.where(business_id: business.id).to_a
      if questions.present?
        sanitized_anwers = self.bookings_answers.select do |answer|
          questions.map(&:id).include?(answer.question_id)
        end
        self.bookings_answers = sanitized_anwers
        self.bookings_answers.each do |answer|
          question = questions.find { |q| q.id == answer.question_id }
          if question
            case question.type
            when 'Text'
              if question.required? && answer&.answer&.content.blank?
                errors.add(:base, 'Some required question is not completed.')
                break
              end
              if answer&.answer&.content.to_s.strip.length >= 300
                errors.add(:base, 'A text answer is too long. Maximum by 300 characters.')
                break
              end
            when 'Checkboxes', 'Radiobuttons'
              if question.required? && answer&.answers.blank?
                errors.add(:base, 'Some required question is not completed.')
                break
              end
            end
          end
        end
      end
    end
  end

  # Validate availability not full
  validate do
    if availability && availability.appointments_count >= availability.max_appointment
      errors.add(:base, 'Sorry. The availability is fully booked. Please select another one.')
    end
  end

  validates :privacy_policy,
            presence: true,
            acceptance: {
              accept: ['1', 'yes', true],
              message: 'must be accepted'
            }

  def availability
    @availability ||= Availability.find_by(id: availability_id)
  end

  def home_visit_appointment?
    availability.home_visit?
  end

  def appointment_type
    @appointment_type ||= AppointmentType.find_by(id: appointment_type_id)
  end

end
