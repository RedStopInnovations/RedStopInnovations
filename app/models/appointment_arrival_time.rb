# == Schema Information
#
# Table name: appointment_arrival_times
#
#  id              :integer          not null, primary key
#  appointment_id  :integer
#  arrival_at      :datetime
#  error           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sent_at         :datetime
#  travel_distance :decimal(10, 2)
#
# Indexes
#
#  index_appointment_arrival_times_on_appointment_id  (appointment_id)
#

class AppointmentArrivalTime < ApplicationRecord
  belongs_to :appointment
end
