module Common
  module AddressLengthValidations
    extend ActiveSupport::Concern
    included do
      validates :address1, :address2,
                length: { maximum: 150 },
                allow_nil: true,
                allow_blank: true

      validates :city,
                length: { maximum: 50 },
                allow_nil: true,
                allow_blank: true

      validates :state,
                length: { maximum: 50 },
                allow_nil: true,
                allow_blank: true

      validates :postcode,
                length: { maximum: 50 },
                allow_nil: true,
                allow_blank: true

      validates :country,
                length: { maximum: 50 },
                allow_nil: true,
                allow_blank: true
    end
  end
end
