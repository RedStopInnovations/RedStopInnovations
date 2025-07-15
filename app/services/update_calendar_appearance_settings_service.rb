class UpdateCalendarAppearanceSettingsService
  attr_reader :business

  def call(business, params)
    settings = business.calendar_appearance_setting
    raw_params = params.to_h

    CalendarAppearanceSetting.transaction do
      if settings.nil?
        settings = CalendarAppearanceSetting.new business: business
      end

      settings.assign_attributes(
        appointment_type_colors: raw_params[:appointment_type_colors],
        availability_type_colors: raw_params[:availability_type_colors],
        is_show_tasks: raw_params[:is_show_tasks]
      )

      # Sync the "color" column in appointment_types table
      appointment_type_id_colors_map = {}

      raw_params[:appointment_type_colors].each do |at_color|
        appointment_type_id_colors_map[at_color[:id]] = at_color[:color]
      end

      business.appointment_types.where(id: appointment_type_id_colors_map.keys).each do |at|
        at.color = appointment_type_id_colors_map[at.id]
        at.save!(validate: false)
      end

      business.appointment_types.where('color IS NOT NULL').where.not(id: appointment_type_id_colors_map.keys).update_all(
        color: nil
      )

      settings.save!
    end
  end
end