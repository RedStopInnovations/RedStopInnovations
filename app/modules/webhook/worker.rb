module Webhook
  class Worker < ::ApplicationJob
    def perform(resource_id, event)
      case event
      when WebhookSubscription::AVAILABILITY_CREATED
        availability = ::Availability.find(resource_id)
        Webhook::Availability::CreatedEventHandler.new(availability).call
      when 'appointment_created'
        appt = ::Appointment.find(resource_id)
        Webhook::Appointment::CreatedEventHandler.new(appt).call
      when 'patient_created'
        patient = ::Patient.find(resource_id)
        Webhook::Patient::CreatedEventHandler.new(patient).call
      when WebhookSubscription::CONTACT_CREATED
        contact = ::Contact.find(resource_id)
        Webhook::Contact::CreatedEventHandler.new(contact).call
      when WebhookSubscription::INVOICE_CREATED
        invoice = ::Invoice.find(resource_id)
        Webhook::Invoice::CreatedEventHandler.new(invoice).call
      when WebhookSubscription::PAYMENT_CREATED
        payment = ::Payment.find(resource_id)
        Webhook::Payment::CreatedEventHandler.new(payment).call
      when WebhookSubscription::TASK_CREATED
        task = ::Task.find(resource_id)
        Webhook::Task::CreatedEventHandler.new(task).call
      when WebhookSubscription::TREATMENT_NOTE_CREATED
        treatment = ::Treatment.find(resource_id)
        Webhook::TreatmentNote::CreatedEventHandler.new(treatment).call
      end
    end
  end
end
