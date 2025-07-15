json.invoices do
  json.array! @invoices, partial: 'api/invoices/invoice', as: :invoice
end