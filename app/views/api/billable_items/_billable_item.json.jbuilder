json.extract! billable_item, :id, :name, :description, :item_number, :tax_id

json.set! :price, billable_item.price.to_f

json.pricing_contacts do
  json.array! billable_item.pricing_contacts, :contact_id, :price
end

json.set! :tax do
  if billable_item.tax
    json.extract! billable_item.tax, :id, :name, :rate
  end
end