# set to true for geocoding
# we recommend configuring local geocoding first
# see https://github.com/ankane/authtrail#geocoding
AuthTrail.geocode = false

# add or modify data
# AuthTrail.transform_method = lambda do |data, request|
#   data[:request_id] = request.request_id
# end

# exclude certain attempts from tracking
AuthTrail.exclude_method = lambda do |data|
  # Skip if for login as from admin
  data[:context] == "admin/users#login_as"
end

# Store the user on failed attempts
# AuthTrail.transform_method = lambda do |data, request|
#   data[:user] ||= User.find_by(email: data[:identity])
# end