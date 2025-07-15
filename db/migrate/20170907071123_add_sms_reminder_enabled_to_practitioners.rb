class AddSmsReminderEnabledToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :sms_reminder_enabled, :boolean, default: false
  end
end
