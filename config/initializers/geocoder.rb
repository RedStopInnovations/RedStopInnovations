if Rails.env.test?
  Geocoder.configure(lookup: :test)

  Geocoder::Lookup::Test.set_default_stub(
    [
      {
        latitude: 40.7143528,
        longitude: -74.0059731,
        address: 'New York, NY, USA',
        state: 'New York',
        state_code: 'NY',
        country: 'United States',
        country_code: 'US'
      }
    ]
  )
else
  Geocoder.configure(
    timeout: 10,
    lookup: :google,
    google: {
      api_key: ENV['GOOGLE_API_KEY']
    },
    ip_lookup: :freegeoip,
    units: :km,
    cache: Redis.new,
    cache_prefix: 'geocoder_',
  )
end
