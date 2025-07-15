# == Schema Information
#
# Table name: appointment_arrivals
#
#  id                   :bigint           not null, primary key
#  appointment_id       :integer
#  sent_at              :datetime
#  arrival_at           :datetime
#  travel_distance      :decimal(10, 2)
#  travel_duration      :integer
#  error                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  travel_start_address :string
#  travel_dest_address  :string
#
# Indexes
#
#  index_appointment_arrivals_on_appointment_id  (appointment_id)
#

class AppointmentArrival < ApplicationRecord
  belongs_to :appointment
end
