module Webhook
  module Invoice
    class Serializer

      attr_reader :invoice

      def initialize(invoice)
        @invoice = invoice
      end

      def as_json(options = {relations: true})
        attrs = invoice.attributes.symbolize_keys.slice(
          :id,
          :invoice_number,
          :issue_date,
          :amount,
          :outstanding,
          :deleted_at,
          :updated_at,
          :created_at
        )
        attrs[:outstanding] = invoice.outstanding.to_f
        attrs[:amount] = invoice.amount.to_f
        attrs[:case] = invoice.patient_case&.case_type&.title

        if options[:relations]
          attrs[:patient] = Webhook::Patient::Serializer.new(invoice.patient).as_json
          if invoice.appointment
            attrs[:appointment] = Webhook::Appointment::Serializer.new(invoice.appointment).as_json({relations: false})
          end

          if invoice.invoice_to_contact
            attrs[:invoice_to_contact] =  Webhook::Contact::Serializer.new(invoice.invoice_to_contact).as_json
          end

          attrs[:items] = []
          invoice.items.each do |item|
            attrs[:items] << Webhook::InvoiceItem::Serializer.new(item).as_json
          end
        end
        attrs
      end
    end
  end
end