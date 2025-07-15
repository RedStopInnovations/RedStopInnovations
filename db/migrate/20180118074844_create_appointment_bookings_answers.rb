class CreateAppointmentBookingsAnswers < ActiveRecord::Migration[5.0]
  def change
    create_table :appointment_bookings_answers do |t|
      t.integer :appointment_id, null: false, index: true
      t.integer :question_id, null: false
      t.text :question_title, null: false
      t.text :answer
      t.text :answers
    end
  end
end
