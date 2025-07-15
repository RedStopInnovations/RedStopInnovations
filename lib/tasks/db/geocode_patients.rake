namespace :db do
  task geocode_patients: :environment do
    def log(what)
      puts what
    end

    business_id = ENV['business_id']

    if business_id.blank?
      raise ArgumentError, "business_id argument is missing!"
    end

    @business = Business.find(business_id)
    patients_count = @business.patients.where('address1 IS NOT NULL AND latitude IS NULL AND longitude IS NULL').count

    log "Business to processed: ##{@business.name}"
    log "Not geocoded patients: #{patients_count}"

    print "Type \"OK\" to continue: "
    continue_confirm = STDIN.gets.chomp
    if continue_confirm != 'OK'
      log "Cancelled due to not confirmed"
      exit(0)
    end

    geocoded_count = 0

    @business.patients
      .where('address1 IS NOT NULL AND latitude IS NULL AND longitude IS NULL')
      .find_each do |patient|

      address = patient.full_address

      if address
        geocode_results = Geocoder.search address

        if geocode_results.present?
          coords = geocode_results[0].geometry['location']
          puts "Patient ##{patient.id}: #{coords.to_s}"
          patient.update_columns(
            latitude: coords['lat'],
            longitude: coords['lng']
          )
        else
          puts "Geocode not found"
        end

        geocoded_count += 1
      end

      if geocoded_count % 100 === 0
        puts "Geocoded: #{geocoded_count}"
        puts "Sleeping ..."
        sleep(10)
      end
    end

  end
end