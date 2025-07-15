json.extract! invoice, :id, :issue_date, :patient_id, :notes, :message, :invoice_number, :service_date,
              :created_at, :updated_at
json.subtotal invoice.subtotal.to_f
json.amount invoice.amount.to_f
json.outstanding invoice.outstanding.to_f
