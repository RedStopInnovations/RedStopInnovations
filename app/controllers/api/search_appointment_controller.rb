module Api
  class SearchAppointmentController < BaseController
    def index
      filters = parse_search_appointment_filters
      @result = SearchAppointment::Searcher.new(filters).result
    end

    private

    def parse_search_appointment_filters
      filters = SearchAppointment::Filters.new(
        params.to_unsafe_h.slice(
          :availability_type_id,
          :practitioner_group_id,
          :practitioner_id,
          :patient_id,
          :profession,
          :location,
          :distance,
          :start_date,
          :end_date,
          :page,
          :per_page
        )
      )

      filters.business_id = current_business.id
      if filters.distance.blank?
        filters.distance = 20
      end
      filters
    end
  end
end
