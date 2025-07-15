class AddSourceAppointmentIdToReviews < ActiveRecord::Migration[5.2]
  def change
    add_column :reviews, :source_appointment_id, :integer, index: true
  end
end
