class NewsletterSubscribeForm < BaseForm
  attribute :email, String

  validates :email,
            presence: true,
            email: true,
            length: { maximum: 150 }
end