class InvoiceActivity
  attr_reader :date, :description, :author

  def initialize(date:, description:, author: nil)
    @author = author
    @date = date
    @description = description
  end

  def self.fetch(invoice)
    events = []

    # Create/update/delete invoice events
    invoice.versions.each do |paper_trail_version|
      case paper_trail_version.event
      when 'create'
        amount_at_version = paper_trail_version.changeset['amount'].try(:[], 1)
        events << new(
          date: paper_trail_version.created_at,
          author: paper_trail_version.author&.full_name,
          description: "Created the invoice. Invoice amount is $#{amount_at_version}."
        )
      when 'update'
        if paper_trail_version.changeset.key?('amount')
          amount_at_version = paper_trail_version.changeset['amount'].try(:[], 1)
        else
          amount_at_version = paper_trail_version.reify.try(&:amount)
        end
        events << new(
          date: paper_trail_version.created_at,
          author: paper_trail_version.author&.full_name,
          description: "Updated the invoice. Invoice amount is $#{amount_at_version}."
        )
      when 'destroy'
        amount_at_version = paper_trail_version.reify.try(&:amount)
        events << new(
          date: paper_trail_version.created_at,
          author: paper_trail_version.author&.full_name,
          description: "Voided the invoice. Invoice amount is $#{amount_at_version}."
        )
      end
    end

    # Communications
    communications = Communication.where(source: invoice).each do |com|
      case com.category
      when 'invoice_send'
        if com.recipient_type == Patient.name
          events << new(
            date: com.created_at,
            description: 'Sent invoice email to the client.'
          )
        elsif com.recipient_type == Contact.name
          events << new(
            date: com.created_at,
            description: "Sent invoice email to #{com.recipient&.business_name.presence || 'the contact'}."
          )
        end
      when 'invoice_outstanding_reminder'
        if com.recipient_type == Patient.name
          events << new(
            date: com.created_at,
            description: 'Sent outstanding reminder email to the client.'
          )
        elsif com.recipient_type == Contact.name
          events << new(
            date: com.created_at,
            description: "Sent outstanding reminder email to #{com.recipient&.business_name.presence || 'the contact'}."
          )
        end
      when 'invoice_payment_remittance'
        if com.recipient_type == Patient.name
          events << new(
            date: com.created_at,
            description: 'Sent payment remittance email to the client.'
          )
        elsif com.recipient_type == Contact.name
          events << new(
            date: com.created_at,
            description: "Sent payment remittance email to #{com.recipient&.business_name.presence || 'the contact'}."
          )
        end
      end
    end

    # Payments
    invoice.payment_allocations.includes(:payment).each do |pa|
      payment = pa.payment

      events << new(
        date: pa.created_at,
        description: "Added a payment for $#{pa.amount}."
      )
    end

    events.sort_by do |event|
      event.date.to_i
    end
  end
end