module Api
  class AppearanceSettingsController < BaseController
    def show
      render(
        json: {
          settings: load_settings
        }
      )
    end

    def update
      authorize! :update, :calendar_appearance_settings

      UpdateCalendarAppearanceSettingsService.new.call(current_business, update_calendar_appearance_setting_params)

      render(
        json: {
          settings: load_settings
        }
      )
    end

    private

    def default_settings
      {
        availability_type_colors: [
          {
            id: AvailabilityType::TYPE_HOME_VISIT_ID,
            color: '#44b654',
          },
          {
            id: AvailabilityType::TYPE_FACILITY_ID,
            color: '#3d88ad',
          },
          {
            id: AvailabilityType::TYPE_NON_BILLABLE_ID,
            color: '#8d41c5',
          },
          {
            id: AvailabilityType::TYPE_GROUP_APPOINTMENT_ID,
            color: '#cddc39',
          }
        ],
        appointment_type_colors: [],
        is_show_tasks: false
      }
    end

    def update_calendar_appearance_setting_params
      params.permit(:is_show_tasks, availability_type_colors: [:id, :color], appointment_type_colors: [:id, :color])
    end

    def load_settings
      settings = current_business.calendar_appearance_setting

      if settings.nil?
        settings = default_settings
      else
        # When new availability type added, need this logic to add missing types to saved settings
        missing_availability_type_ids = default_settings[:availability_type_colors].pluck(:id) - settings.availability_type_colors.pluck('id')

        if missing_availability_type_ids.present?
          settings.availability_type_colors += default_settings[:availability_type_colors].filter do |at|
            missing_availability_type_ids.include? at[:id]
          end
        end
      end

      settings
    end
  end
end