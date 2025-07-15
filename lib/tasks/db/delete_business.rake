namespace :db do
  task delete_business: :environment do
    def perform(business)
      practitioner_ids = business.practitioners.pluck(:id)
      user_ids = business.users.pluck(:id)
      # Appointment types
      AppointmentType.where(business_id: business.id).delete_all

      # Appointments
      business.appointments.with_deleted.destroy_all

      # Availability
      business.availabilities.delete_all
      AvailabilityRecurring.where(practitioner_id: practitioner_ids).delete_all

      # Billable items
      BillableItem.where(business_id: business.id).destroy_all

      # Integrations
      BusinessMailchimpSetting.where(business_id: business.id).delete_all
      BusinessMedipassAccount.where(business_id: business.id).delete_all
      BusinessStripeAccount.where(business_id: business.id).delete_all
      BusinessTutorial.where(business_id: business.id).delete_all

      # Case types
      CaseType.where(business_id: business.id).delete_all

      # Communications
      Communication.where(business_id: business.id).delete_all
      CommunicationTemplate.where(business_id: business.id).delete_all

      # Contacts
      Contact.where(business_id: business.id).with_deleted.delete_all

      # Settings
      BusinessSetting.where(business_id: business.id).delete_all

      # Groups
      Group.where(business_id: business.id).delete_all

      # Patient imports
      Import.where(business_id: business.id).delete_all

      # Invoices
      invoice_ids = Invoice.with_deleted.where(business_id: business.id).pluck(:id)
      Invoice.where(id: invoice_ids).with_deleted.delete_all
      InvoiceItem.where(invoice_id: invoice_ids).destroy_all
      MedipassQuote.where(invoice_id: invoice_ids).delete_all

      InvoiceSetting.where(business_id: business.id).delete_all

      # LetterTemplate
      LetterTemplate.where(business_id: business.id).delete_all

      # OutcomeMeasure
      ocm_type_ids = OutcomeMeasureType.where(business_id: business.id).pluck(:id)
      OutcomeMeasureType.where(id: ocm_type_ids).delete_all
      OutcomeMeasure.where(outcome_measure_type_id: ocm_type_ids).destroy_all

      # Payment
      PaymentType.where(business_id: business.id).delete_all
      payment_ids = Payment.with_deleted.where(business_id: business.id).pluck(:id)
      MedipassTransaction.where(invoice_id: invoice_ids).delete_all
      Payment.where(id: payment_ids).with_deleted.delete_all

      # Post
      Post.where(practitioner_id: practitioner_ids).destroy_all

      # Product
      Product.where(business_id: business.id).destroy_all

      # Referral
      Referral.where(business_id: business.id).destroy_all
      ReferralEnquiryQualification.where(practitioner_id: practitioner_ids).delete_all

      # Review
      Review.where(practitioner_id: practitioner_ids).delete_all

      # Task
      Task.where(business_id: business.id).delete_all

      # Tax
      Tax.where(business_id: business.id).delete_all

      # Waitlist
      WaitList.where(business_id: business.id).delete_all

      # Treatment & templates
      treatment_template_ids = TreatmentTemplate.with_deleted.where(business_id: business.id).pluck(:id)
      treatment_template_section_ids = TreatmentTemplateSection.where(template_id: treatment_template_ids).pluck(:id)
      TreatmentContent.delete_all
      Treatment.where(treatment_template_id: treatment_template_ids).delete_all
      Treatment.where(practitioner_id: practitioner_ids).delete_all
      TreatmentTemplateQuestion.where(section_id: treatment_template_section_ids).delete_all
      TreatmentTemplateSection.where(template_id: treatment_template_ids).delete_all
      TreatmentTemplate.with_deleted.where(id: treatment_template_ids).delete_all

      TreatmentShortcut.where(business_id: business.id).delete_all

      # Account statements
      AccountStatement.where(business_id: business.id).delete_all
      # AccountStatementItem

      BookingsQuestion.where(business_id: business.id).delete_all
      PatientAccessSetting.where(business_id: business.id).delete_all
      ClaimingAuthGroup.where(business_id: business.id).destroy_all
      ConversationRoom.where(business_id: business.id).destroy_all
      DeletedResource.where(business_id: business.id).delete_all
      PhysitrackIntegration.where(business_id: business.id).destroy_all
      TriggerCategory.where(business_id: business.id).destroy_all
      WebhookSubscription.where(business_id: business.id).delete_all

      # Patient and associated data
      patient_ids = business.patients.with_deleted.pluck(:id)
      PatientAccess.where(patient_id: patient_ids).delete_all
      PatientAttachment.where(patient_id: patient_ids).destroy_all
      PatientCase.where(patient_id: patient_ids).delete_all
      PatientContact.where(patient_id: patient_ids).delete_all
      PatientIdNumber.where(patient_id: patient_ids).delete_all
      PatientStripeCustomer.where(patient_id: patient_ids).delete_all
      Treatment.where(patient_id: patient_ids).delete_all
      PatientLetter.where(business_id: business.id).delete_all

      Patient.with_deleted.where(id: patient_ids).delete_all
      ContactStatement.where(patient_id: patient_ids).delete_all
      PatientStatement.where(patient_id: patient_ids).delete_all
      IncomingMessage.where(patient_id: patient_ids).delete_all
      Image.where(user_id: user_ids).delete_all

      # Subscription & invoices
      SubscriptionDiscount.where(business_id: business.id).delete_all
      BusinessInvoice.where(business_id: business.id).destroy_all
      SubscriptionPayment.where(business_id: business.id).delete_all
      subscription = business.subscription
      if subscription
        SubscriptionBilling.where(subscription_id: subscription.id).delete_all
      end
      Subscription.find_by(business_id: business.id).destroy
      # Practitioner
      Practitioner.where(id: practitioner_ids).destroy_all
      # User
      User.where(business_id: business.id).destroy_all

      # Good bye
      business.destroy
    end

    business_id = ENV.fetch 'business_id'

    business = Business.find business_id
    puts "!" * 80
    puts "WARNING: You are about delete business ##{business.id} - #{business.name}"
    puts "!" * 80
    puts "Joined at: #{business.created_at}"
    puts "Last sign in at: #{business.users.order(id: :asc).first&.current_sign_in_at}"
    puts "No. of patients: #{business.patients.with_deleted.count}"
    puts "No. of messages: #{business.communications.count}"
    puts "No. of users: #{business.users.count}"
    puts "No. of practitioners: #{business.practitioners.count}"
    puts "No. of avails: #{business.availabilities.count}"
    puts "No. of appts: #{business.appointments.with_deleted.count}"
    puts "No. of invoices: #{business.invoices.with_deleted.count}"
    puts "No. of posts: #{business.posts.count}"
    puts "No. of account statements: #{business.account_statements.count}"

    print "\nConfirm to continue? (Y/n): "
    confirm = STDIN.gets.chomp
    if confirm == 'Y'
      puts "\nOK, working ..."
      ActiveRecord::Base.transaction do
        perform(business)
      end
      puts "\nDone."
    else
      puts "Deletion cancelled"
    end
  end
end
