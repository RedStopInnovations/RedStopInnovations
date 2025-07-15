# App events tracking
Rack::Attack.throttle("App events tracking", limit: 20, period: 1.minutes) do |req|
  if req.path.start_with?("/_trk") && req.post?
    req.ip
  end
end

Rack::Attack.throttled_response = lambda do |env|
  # Using 503 because it may make attacker think that
  # they have successfully DOSed the site
  [ 503, {}, ["Service Unavailable\n"]]
end

# Ban login scrapers
Rack::Attack.blocklist('allow2ban login scrapers') do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 1.hour) do
    req.path.end_with?('/users/sign_in') and req.post?
  end
end

Rack::Attack.blocklisted_response = lambda do |request|
  [ 503, {}, ['Service Unavailable']]
end