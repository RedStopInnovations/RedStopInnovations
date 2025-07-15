namespace :import do
  task import_billable_items_csv: :environment do
    def log(what)
      puts what
    end

    def transform_data(row)
      data = {
        name: row['Name'].to_s.strip,
        description: row['Description'].to_s.strip,
        item_number: row['Item number'].to_s.strip,
        price: row['Price'],
        health_insurance_rebate: row['Rebate'] == 'Yes',
      }

      if row['Tax'].present?
        tax = @business.taxes.find_by(name: row['Tax'].strip)
        if tax
          data[:tax_id] = tax.id
        end
      end

      data
    end

    business_id = ENV['business_id']
    csv_path = ENV['csv']

    if business_id.blank? || csv_path.blank?
      raise ArgumentError, "Business ID or CSV path is missing!"
    end

    @business = Business.find(business_id)
    log "Starting import billable items for business: ##{ @business.id } - #{ @business.name }"

    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp

    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end

    imported_count = 0
    row_index = 0

    item_codes = []
    error_indexes = []

    CSV.foreach(Rails.root.join(csv_path), headers: true) do |row|
      begin
        row_attrs = row.to_h
        parsed_attrs = transform_data row_attrs

        # @TODO: skip duplicate name?
        import_item = BillableItem.new(
          parsed_attrs
        )

        item_codes << parsed_attrs[:item_number]

        import_item.business_id = @business.id
        import_item.save!(validate: false)

        imported_count += 1

        puts "- Created ##{import_item.id}: #{import_item.name} [#{import_item.item_number}]"
      rescue => e
        puts "- Error: #{e.message}. Row index: #{row_index}"
        error_indexes << row_index
      end

      row_index += 1
    end

    if item_codes.size != item_codes.uniq.size
      dups = item_codes.select do |code| item_codes.count(code) > 1 end
      puts "WARNING: duplicate item number found: #{dups.join(',')}"
    end

    puts "Import complete"
    puts "Imported: #{imported_count}"
    if !error_indexes.empty?
      puts "Errors: #{error_indexes.size}. Rows: #{error_indexes.join(',')}"
    end
  end
end