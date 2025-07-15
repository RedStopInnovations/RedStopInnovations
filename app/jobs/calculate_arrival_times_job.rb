class CalculateArrivalTimesJob < ApplicationJob
  def perform(availability_id)
    availability = Availability.find availability_id

    if availability.home_visit?
      HomeVisitRouting::ArrivalCalculate.new.call(availability.id)
    elsif availability.facility?
      HomeVisitRouting::FacilityArrivalCalculate.new.call(availability.id)
    end

    AvailabilityCachedStats.new.update availability
  end
end
