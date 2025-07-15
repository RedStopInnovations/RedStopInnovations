module Utils
  module ProfessionHelper
    # Get list of profession order by number of practitioners
    def self.popularity_order_list_by_country(country)
      sanitized_country_code = country.to_s.downcase
      cached_popularity_order_list_by_country sanitized_country_code
    end

    private

    def self.cached_popularity_order_list_by_country(country_code)
      Rails.cache.fetch("#{country_code}__popularity_order_list", expires_in: 7.days) do
        Practitioner.where('profession IS NOT NULL').
          where("profession <> ''").select('profession, COUNT(*) AS practitioners_count').
          where('country' => country_code.upcase).
          order('practitioners_count DESC').
          group('profession').
          to_a.
          pluck('profession')
      end
    end
  end
end