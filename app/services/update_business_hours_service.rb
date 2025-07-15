class UpdateBusinessHoursService
  def call(practitioner, params)
    PractitionerBusinessHour.transaction do
      params[:business_hours].each do |day_of_week_setting|
        setting = PractitionerBusinessHour.find_or_initialize_by(
          practitioner_id: practitioner.id,
          day_of_week: day_of_week_setting[:day_of_week]
        )

        setting.assign_attributes(day_of_week_setting.slice(:active, :availability))
        unless setting.active?
          setting.availability = []
        end
        setting.save
      end
    end
  end
end