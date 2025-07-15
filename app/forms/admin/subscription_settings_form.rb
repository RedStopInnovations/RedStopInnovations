module Admin
  class SubscriptionSettingsForm < BaseForm
    attribute :email, String, default: nil
    attribute :auto_send_invoice, Boolean, default: false
    attribute :auto_payment, Boolean, default: false
    attribute :auto_payment_delay, Integer
    attribute :notify_new_invoice, Boolean, default: true

    validates :auto_payment_delay,
              numericality: {
                only_integer: true,
                greater_than: 0,
                less_than_or_equal_to: 240
              },
              allow_blank: true,
              allow_nil: true

    validates_presence_of :auto_payment_delay, if: :auto_payment

    validates :email, email: true, allow_nil: true, allow_blank: true
  end
end