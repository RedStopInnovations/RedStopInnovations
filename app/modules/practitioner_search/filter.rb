module PractitionerSearch
  class Filter
    include Virtus.model

    attribute :profession, String
    attribute :country, String
    attribute :location, String
    attribute :service, String
    attribute :rate, String
    attribute :max_price, Integer
    attribute :page, Integer, default: 1

    def formatted_price_range
      range = price_range.split('-')
      range.map do |val|
        "$#{val}"
      end.join(' - ')
    end
  end
end
