puts '== Seeding notification types '.ljust(80, '=')
print "Truncate `#{NotificationType.table_name}` table? (Y/n): "

if STDIN.gets.chomp == 'Y'
  NotificationType.delete_all
end

ActiveRecord::Base.transaction do
    YAML.load_file(
      Rails.root.join('db/seeds', 'notification_types.yml')
    ).each do |attrs|
      nt = NotificationType.create!(
        attrs.slice('id', 'name', 'description', 'default_template', 'default_config', 'available_delivery_methods')
      )

      puts "- Created: #{nt.id}"
    end
end