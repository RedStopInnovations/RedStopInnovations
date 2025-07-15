module HomeVisitRouting
  module GoogleApiHelper
    def self.build_direction_query_url(origin, dest, waypoints, options = {})
      optimize = options.key?(:optimize) ? options[:optimize] : false

      URI::Parser.new.escape("https://maps.googleapis.com/maps/api/directions/json?" \
                 "origin=#{origin}&" \
                 "&destination=#{dest}" \
                 "&mode=driving" \
                 "&waypoints=optimize:#{optimize}|#{waypoints.join('|')}"\
                 "&key=#{ENV['GOOGLE_API_KEY']}")
    end
  end
end
