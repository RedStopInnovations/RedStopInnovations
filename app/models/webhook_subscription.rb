# == Schema Information
#
# Table name: webhook_subscriptions
#
#  id           :integer          not null, primary key
#  business_id  :integer          not null
#  user_id      :integer          not null
#  event        :string           not null
#  target_url   :string           not null
#  method       :string
#  event_params :jsonb
#  active       :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_webhook_subscriptions_on_active       (active)
#  index_webhook_subscriptions_on_business_id  (business_id)
#  index_webhook_subscriptions_on_event        (event)
#  index_webhook_subscriptions_on_user_id      (user_id)
#

class WebhookSubscription < ApplicationRecord
  EVENTS = [
    AVAILABILITY_CREATED = 'availability_created',
    APPOINTMENT_CREATED = 'appointment_created',
    CONTACT_CREATED = 'contact_created',
    INVOICE_CREATED = 'invoice_created',
    PATIENT_CREATED = 'patient_created',
    PAYMENT_CREATED = 'payment_created',
    TASK_CREATED = 'task_created',
    TREATMENT_NOTE_CREATED = 'treatment_note_created'
  ]

  validates_presence_of :user_id, :business_id

  validates_presence_of :event
  validates_inclusion_of :event, in: EVENTS,
                         allow_nil: true,
                         allow_blank: true,
                         message: 'is not valid'

  validates_presence_of :target_url

  validates :target_url,
            url: true,
            allow_nil: true,
            allow_blank: true
end
