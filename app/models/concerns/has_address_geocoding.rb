module HasAddressGeocoding
  extend ActiveSupport::Concern
  include Common::AddressLengthValidations

  ADDRESS_ATTRS = %i[address1 address2 city state postcode country]

  included do
    before_save :geocode, if: :needs_regeocode?

    geocoded_by :full_address_for_geocoding

    def full_address
      [
        address2, address1, city, state, postcode, country
      ].map(&:presence).compact.join(', ')
    end

    def short_address
      [
        address2, address1, city, "#{state} #{postcode}"
      ].map(&:presence).compact.join(', ')
    end

    def address_changed?
      ADDRESS_ATTRS.any? { |attr| changed.include?(attr.to_s) }
    end

    def geocodeable?
      full_address.present?
    end

    def needs_regeocode?
      full_address.present? && (
        (persisted? && address_changed?) ||(new_record? && !geocoded?)
      )
    end

    def full_address_for_geocoding
      [
        address1, city, state, postcode, country_name
      ].map(&:presence).compact.join(', ')
    end

    def country_name
      if country
        return ISO3166::Country[country]&.iso_short_name
      end
    end
  end
end
