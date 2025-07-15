module Letter
  module Embeddable
    class InvoiceToContact < Base
      VARIABLES = [
        'InvoiceTo.ContactName',
        'InvoiceTo.Title',
        'InvoiceTo.FirstName',
        'InvoiceTo.LastName',
        'InvoiceTo.FullName',
        'InvoiceTo.Email',
        'InvoiceTo.Phone',
        'InvoiceTo.Mobile',
        'InvoiceTo.Fax',
        'InvoiceTo.FullAddress',
        'InvoiceTo.Address1',
        'InvoiceTo.Address2',
        'InvoiceTo.City',
        'InvoiceTo.State',
        'InvoiceTo.PostCode',
        'InvoiceTo.Country'
      ]

      # @param patient ::Contact
      def initialize(contact)
        @contact = contact
        super map_attributes
      end

      private

      def map_attributes
        map = {
          'InvoiceTo.ContactName' => @contact.business_name,
          'InvoiceTo.Title' => @contact.title,
          'InvoiceTo.FirstName' => @contact.first_name,
          'InvoiceTo.LastName' => @contact.last_name,
          'InvoiceTo.FullName' => @contact.full_name,
          'InvoiceTo.Email' => @contact.email,
          'InvoiceTo.Phone' => @contact.phone,
          'InvoiceTo.Mobile' => @contact.mobile,
          'InvoiceTo.Fax' => @contact.fax,
          'InvoiceTo.FullAddress' => @contact.full_address,
          'InvoiceTo.Address1' => @contact.address1,
          'InvoiceTo.Address2' => @contact.address2,
          'InvoiceTo.City' => @contact.city,
          'InvoiceTo.State' => @contact.state,
          'InvoiceTo.PostCode' => @contact.postcode,
          'InvoiceTo.Country' => @contact.country
        }
        map
      end

    end
  end
end
