class FindDuplicateContactsService
  def call(business, contact)
    @business = business
    @contact = contact
    find_contacts_has_same_name
  end

  private

  def find_contacts_has_same_name
    @business.contacts.where(
      "LOWER(business_name) LIKE :business_name",
      business_name: "%#{@contact.business_name.downcase.strip}%",
      ).
      order(id: :asc).
      where('contacts.id <> ?', @contact.id).
      to_a
  end
end
