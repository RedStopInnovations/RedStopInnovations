class BusinessMailchimpSyncPatients < ApplicationJob
  def perform(business, patient = nil, options = {})
    begin
      unsubscribers = []
      subscribers = []
      mailchimp_setting = business.mailchimp_setting

      mailchimp = Mailchimp::API.new(mailchimp_setting.api_key)
      list_sync = mailchimp.lists.list({list_name: mailchimp_setting.list_name})['data'].first
      return if list_sync.nil?

      if patient.present?
        unsubscribers << { 'email' => options[:email]} if options[:email]

        if options[:destroy]
          unsubscribers << { 'email' => patient.email}
        else
          subscribers << {
            'EMAIL' => { 'email' => patient.email},
            :merge_vars => {
              'FNAME' => patient.first_name,
              'LNAME'  => patient.last_name,
            }
          }
        end
      end

      mailchimp.lists.batch_unsubscribe(list_sync['id'], unsubscribers, true, false, false) if unsubscribers.present?
      mailchimp.lists.batch_subscribe(list_sync['id'], subscribers, false, true, false) if subscribers.present?
    rescue Exception => e
    end
  end
end
