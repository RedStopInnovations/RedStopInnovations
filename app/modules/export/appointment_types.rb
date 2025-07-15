module Export
  class AppointmentTypes
    attr_reader :business

    def self.make(business)
      new(business)
    end

    def initialize(business)
      @business = business
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'Name',
          'Duration',
          'Availability type',
          'Default billable items',
          'Online bookings',
          'Reminder',
          'Description',
          'Creation'
        ]

        appointment_types_query.load.each do |at|
          billable_items_cell = at.billable_items.pluck(:name).join(', ')
          csv << [
            at.name,
            at.duration,
            at.availability_type.name,
            billable_items_cell,
            at.display_on_online_bookings? ? 'Yes' : 'No',
            at.reminder_enable? ? 'Yes' : 'No',
            at.description,
            at.created_at.strftime('%Y-%m-%d')
          ]
        end
      end
    end

    private

    def appointment_types_query
      business.appointment_types.not_deleted.order(name: :asc)
    end
  end
end
