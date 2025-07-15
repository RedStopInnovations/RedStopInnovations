json.billable_items do
  json.array! @billable_items, partial: 'api/billable_items/billable_item', as: :billable_item
end
