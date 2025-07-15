class CreateCalendarAppearanceSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :calendar_appearance_settings do |t|
      t.integer :business_id, null: false, index: true
      t.text  :availability_type_colors
      t.text  :appointment_type_colors
    end
  end
end
