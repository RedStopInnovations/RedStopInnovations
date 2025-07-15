class UpdateInvoiceSettingsForm < BaseForm
  attr_accessor :business

  attribute :starting_invoice_number, Integer, default: 1
  attribute :messages, String, default: nil

  validates :starting_invoice_number,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than: 10_000_000_000 # Is it enough? :)
            }

  validates_length_of :messages, maximum: 1000

  def self.build_for_business(business)
    attrs = {
      business: business
    }

    current_invoice_setting = business.invoice_setting

    attrs[:starting_invoice_number] = current_invoice_setting.try(:starting_invoice_number)
    attrs[:messages] = current_invoice_setting.try(:messages)

    new(attrs)
  end
end