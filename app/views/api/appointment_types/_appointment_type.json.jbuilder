json.extract! appointment_type,
              :id,
              :business_id,
              :name,
              :description,
              :item_number,
              :duration,
              :price,
              :availability_type,
              :availability_type_id,
              :practitioner_ids,
              :deleted_at,
              :color

json.billable_items do
  json.array! appointment_type.billable_items, partial: 'api/billable_items/billable_item', as: :billable_item
end

