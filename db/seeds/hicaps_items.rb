puts '== Seeding HICAPS items '.ljust(80, '=')
print "Delete entry `#{HicapsItem.table_name}` table? (Y/n): "

if STDIN.gets.chomp == 'Y'
  HicapsItem.delete_all
end

ActiveRecord::Base.transaction do
  csv = CSV.parse(
    File.read(Rails.root.join('db', 'seeds', 'hicaps_items.csv')),
    quote_char: '"'
  )

  csv.each_with_index do |row, i|
    next if row.length == 0 # Skip blank lines
    next if row[0].start_with?('#') # Skip comment

    # Validates
    if row.length > 4
      puts "Skipped line #{i + 1}. Error: has more than 4 columns."
      next
    end

    if row.length < 2
      puts "Skipped line #{i + 1}. Error: missing required info: item number and description."
      next
    end

    unless row[0] !~ /\D/
      puts "Skipped line #{i + 1}. Error: the item number is invalid."
      next
    end

    # Insert to db
    HicapsItem.create(
      item_number: row[0].strip,
      description: row[1].strip,
      abbr: row[2].try(:strip),
      category: row[3].try(:strip)
    )
  end
end

puts '== Seeding HICAPS items done '.ljust(80, '=')
