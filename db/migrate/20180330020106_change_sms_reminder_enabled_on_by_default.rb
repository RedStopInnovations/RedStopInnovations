class ChangeSmsReminderEnabledOnByDefault < ActiveRecord::Migration[5.0]
  def change
    change_column :practitioners, :sms_reminder_enabled, :boolean, default: true
  end
end
