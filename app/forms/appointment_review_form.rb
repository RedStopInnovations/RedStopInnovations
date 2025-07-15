class AppointmentReviewForm < BaseForm
  attribute :score, Integer
  attribute :comment, String

  validates :comment,
            presence: true,
            length: { minimum: 10, maximum: 1000 }

  validates :score,
            presence: true,
            inclusion: { in: [1, 2, 3, 4, 5] }
end