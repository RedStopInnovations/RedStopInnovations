# == Schema Information
#
# Table name: appointment_bookings_answers
#
#  id             :integer          not null, primary key
#  appointment_id :integer          not null
#  question_id    :integer          not null
#  question_title :text             not null
#  answer         :text
#  answers        :text
#
# Indexes
#
#  index_appointment_bookings_answers_on_appointment_id  (appointment_id)
#

class AppointmentBookingsAnswer < ApplicationRecord
  serialize :answer, type: Hash
  serialize :answers, type: Array

  belongs_to :question, class_name: 'BookingsQuestion'
end
