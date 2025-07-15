class SendAccountStatementToOthersService
  # @param statement AccountStatement
  # @param form SendOthersForm
  def call(account_statement, form)
    @account_statement = account_statement
    business = account_statement.business

    contacts = business.
      contacts.
      where("email <> ''").
      where(id: form.contact_ids)

    message = form.message.to_s.strip

    if contacts.present?
      contacts.each do |contact|
        com = business.communications.create!(
          message_type: Communication::TYPE_EMAIL,
          recipient: contact,
          linked_patient_id: @account_statement.source_id,
          message:  message,
          category: 'account_statement_send',
          source: @account_statement
        )

        com_delivery = CommunicationDelivery.create!(
          communication_id: com.id,
          recipient: contact.email,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          status: CommunicationDelivery::STATUS_SCHEDULED,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
        )

        PatientAccountStatementMailer.send_to_contact(
          @account_statement,
          contact,
          message,
          sendgrid_delivery_tracking_id: com_delivery.tracking_id
        ).deliver_later
      end
    end

    if form.emails.present?
      form.emails.each do |email|
        PatientAccountStatementMailer.send_to_email(
          @account_statement,
          email,
          message
        ).deliver_later
      end
    end

    send_ts = Time.current
    @account_statement.invoices.update_all(
      last_send_at: send_ts
    )
    @account_statement.update_column :last_send_at, send_ts
  end
end
