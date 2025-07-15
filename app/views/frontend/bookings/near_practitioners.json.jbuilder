json.practitioners do
    json.array! @near_practitioners do |pract|
        json.extract! pract, :slug, :full_name, :profession, :city, :state, :postcode, :distance
        json.business_phone pract.business.phone
        json.business_email pract.business.email
        json.avatar_url pract.profile_picture_url(:medium)
        json.local_latitude pract.local_latitude
        json.local_longitude pract.local_longitude
    end
end
