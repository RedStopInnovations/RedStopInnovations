json.invoices do
  json.array! @outstanding_invoices, partial: 'invoices/invoice', as: :invoice
end
