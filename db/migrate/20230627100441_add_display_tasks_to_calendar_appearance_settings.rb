class AddDisplayTasksToCalendarAppearanceSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :calendar_appearance_settings, :is_show_tasks, :boolean, default: false
  end
end
