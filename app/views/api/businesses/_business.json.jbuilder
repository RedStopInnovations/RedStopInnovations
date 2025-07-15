json.extract! business,
             :id,
             :name,
             :phone,
             :mobile,
             :website,
             :email,
             :avatar,
             :short_address,
             :full_address,
             :country,
             :latitude,
             :longitude

json.practitioners do
  practitioners = business.active_practitioners.where(users: {is_practitioner: true}).order('practitioners.full_name asc').includes(:business_hours)
  json.array! practitioners, partial: 'practitioners/practitioner', as: :practitioner
end

json.appointment_types do
  json.array! business.appointment_types.order(deleted_at: :desc, name: :asc).includes(:practitioners), partial: 'appointment_types/appointment_type', as: :appointment_type
end

json.groups do
  json.array! business.groups.includes(:practitioners).order(name: :asc), :id, :name, :practitioner_ids
end

json.professions do
  json.array! business.practitioners.pluck('DISTINCT profession').select(&:present?)
end

json.availability_subtypes do
  json.array! business.availability_subtypes.select(:id, :name, :deleted_at).to_a
end
