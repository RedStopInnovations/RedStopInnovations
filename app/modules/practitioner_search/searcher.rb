module PractitionerSearch
  class Searcher
    attr_reader :filter

    def initialize(filter)
      @filter = filter
    end

    def result
      query = base_scope

      query = filter_profession(query)
      query = filter_country(query)
      query = filter_service(query)
      query = filter_rate(query)
      query = filter_max_price(query)
      query = filter_location(query)

      query = order(query)
      query = eager_load(query)
      query = paginate(query)

      query.load
    end

    private

    def filter_profession(query)
      if filter.profession.present?
        query = query.where(profession: filter.profession)
      end
      query
    end

    def filter_country(query)
      if filter.country.present?
        query = query.where(country: filter.country)
      end
      query
    end

    def filter_location(query)
      if filter.location.present?
        query = query.where(country: filter.country)
        if filter.location =~ /\A\d+\z/ # postcode
          coordinates = Geocoder.coordinates "#{filter.location}, #{filter.country}"
          query = query.near(coordinates, 20, unit: :km)
        else # city
          query = query.where('LOWER(practitioners.city) LIKE ?', "%#{filter.location.downcase}%")
        end
      end
      query
    end

    def filter_service(query)
      if filter.service.present?
        query = query.joins(:billable_items).where(
          'billable_items.deleted_at IS NULL AND billable_items.display_on_pricing_page = ? AND LOWER(billable_items.name) LIKE ?',
          true,
          "%#{filter.service.downcase}%"
        )
      end

      query
    end

    def filter_rate(query)
      if filter.rate.present?
        query = query.where(
          'practitioners.rating_score >= ?', filter.rate
        )
      end

      query
    end

    def filter_max_price(query)
      if filter.max_price.present?
        query = query.joins(:billable_items).where(
          'billable_items.deleted_at IS NULL AND billable_items.price <= ? AND billable_items.display_on_pricing_page = ?',
          filter.max_price,
          true
        )
      end

      query
    end

    def order(query)
      query.order(rating_score: :desc, full_name: :asc)
    end

    def paginate(query)
      query.page(filter.page).per(20)
    end

    def eager_load(query)
      query.includes([:user, :business])
    end

    def base_scope
      Practitioner.
        approved.
        active.
        public_profile
    end
  end
end
