module WaitListSearch
  class Searcher
    attr_reader :business, :filter

    def initialize(business: , filter:)
      @filter = filter
      @business = business
    end

    def result
      query = business.wait_lists.not_scheduled.
        includes(:patient, :appointment_type, practitioner: [:user]).
        joins(:patient).
        where(patients: {archived_at: nil, deleted_at: nil}).
        order(date: :asc)

      # Search by location
      if filter[:patient_search].blank? && filter[:location_search].present?

        location_keyword = filter[:location_search].strip

        if location_keyword =~ /\A\d+\z/ # Postcode
          query = query.where('patients.postcode = ?', location_keyword)
        else !(location_keyword =~ /\d/) # Has not a number. This is city or state
          loc_info = Geocoder.search("#{location_keyword}, #{business.country}").first

          if loc_info
            if loc_info.types == ['street_address']
              query = query.near(loc_info.coordinates, 20)
            elsif loc_info.types == ['postal_code']
              query = query.where('patients.postcode = ?', location_keyword)
            elsif loc_info.types.sort == ['political', 'administrative_area_level_1'].sort # State
              addr_cmp = loc_info.address_components.find do |ac|
                ac['types'].sort == ['political', 'administrative_area_level_1'].sort
              end
              if addr_cmp
                query = query.where(
                  'LOWER(patients.state) IN (?)',
                  [addr_cmp['short_name'].downcase, addr_cmp['long_name'].downcase]
                )
              end

            elsif loc_info.types.all? { |type| ['colloquial_area', 'locality', 'political'].include?(type) }
              addr_cmp = loc_info.address_components.find do |ac|
                ac['types'].sort == ['locality', 'political'].sort
              end
              if addr_cmp.nil?
                addr_cmp = loc_info.address_components.find do |ac|
                  ac['types'].sort == ['colloquial_area', 'locality', 'political'].sort
                end
              end
              if addr_cmp
                query = query.where(
                  'LOWER(patients.city) IN (?)',
                  [addr_cmp['short_name'].downcase, addr_cmp['long_name'].downcase]
                )
              end
            end
          end
        end
      end

      query.
        ransack(build_ransack_query).
        result
    end

    private

    def build_ransack_query
      q = {}

      if filter.patient_search.present?
        q[:patient_full_name_cont] = filter.patient_search
      end

      if filter.profession.present?
        q[:profession_eq] = filter.profession
      end

      if filter.appointment_type_id.present?
        q[:appointment_type_id_eq] = filter.appointment_type_id
      end

      if filter.practitioner_id.present?
        q[:practitioner_id_eq] = filter.practitioner_id
      end

      q
    end
  end
end
