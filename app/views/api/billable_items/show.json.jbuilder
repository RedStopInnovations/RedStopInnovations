json.billable_item do
  json.partial! 'api/billable_items/billable_item', billable_item: @billable_item
end
