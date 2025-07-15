class MergeContactsService
  # @param target_contact Contact
  # @param selected_contacts Array
  # @param current_user User
  def call(target_contact, selected_contacts, current_user)
    @target_contact = target_contact
    @selected_contacts = selected_contacts.sort_by(&:updated_at).reverse
    @current_user = current_user

    @merge_history = MergeResourcesHistory.new(
      resource_type: Contact.name,
      author_id: current_user.id,
      target_resource_id: @target_contact.id,
      merged_resource_ids: @selected_contacts.map(&:id),
      meta: build_merge_resources_history_meta
    )

    ActiveRecord::Base.transaction do
      merge_details_info
      merge_invoices
      merge_communications
      merge_account_statements
      merge_associated_patients
      merge_billable_items
      merge_availability
      delete_merged_contacts
      @merge_history.save!
    end
  end

  private

  def selected_contact_ids
    @selected_contact_ids ||= @selected_contacts.map(&:id)
  end

  def merge_details_info
    %i[
      title first_name last_name mobile phone fax
      address1 address2 city state postcode country
      notes
    ].each do |attr|
      if @target_contact[attr].blank?
        @target_contact[attr] =
          @selected_contacts.map(&:"#{attr}").find(&:present?)
      end
    end

    @target_contact.save!(validate: false)
  end

  def merge_invoices
    Invoice.with_deleted.where(invoice_to_contact_id: selected_contact_ids).
      update_all(
        invoice_to_contact_id: @target_contact.id,
        updated_at: Time.current
      )
  end

  def merge_communications
    Communication.where(
        recipient_type: Contact.name,
        recipient_id: selected_contact_ids)
      .update_all(
        recipient_id: @target_contact.id,
        updated_at: Time.current
      )
  end

  def merge_account_statements
    AccountStatement.where(
      source_type: Contact.name,
      source_id: selected_contact_ids
    ).update_all(
      source_id: @target_contact.id,
      updated_at: Time.current
    )
  end

  def merge_associated_patients
    PatientContact.where(contact_id: selected_contact_ids).each do |pa|
      pa.update(
        contact_id: @target_contact.id,
        updated_at: Time.current
      )
    end
  end

  def merge_billable_items
    BillableItemsContacts.where(contact_id: selected_contact_ids).update_all(
      contact_id: @target_contact.id
    )
  end

  def merge_availability
    Availability.where(contact_id: selected_contact_ids).update_all(
      contact_id: @target_contact.id,
      updated_at: Time.current
    )
  end

  def delete_merged_contacts
    @selected_contacts.each do |contact|
      contact.destroy_by_author(@current_user)
    end
  end

  def build_merge_resources_history_meta
    target_resource_attrs = @target_contact.attributes

    target_resource_attrs.merge!(
      patients_count: @target_contact.patients.count(Arel.sql('DISTINCT patients.id')),
      invoices_count: @target_contact.invoices.count,
      communications_count: Communication.where(recipient: @target_contact).count,
      account_statements_count: @target_contact.account_statements.not_deleted.count
    ).deep_stringify_keys!

    merged_resources_attrs = @selected_contacts.map do |contact|
      attrs = contact.attributes
      attrs.merge!(
        patients_count: contact.patients.count(Arel.sql('DISTINCT patients.id')),
        invoices_count: contact.invoices.count,
        communications_count: Communication.where(recipient: contact).count,
        account_statements_count: contact.account_statements.not_deleted.count
      ).deep_stringify_keys!
      attrs
    end

    {
      target_resource: target_resource_attrs,
      merged_resources: merged_resources_attrs
    }
  end
end
