module Export
  class PractitionerBusinessHours
    WEEKDAYS = [1, 2, 3, 4, 5] # Mon to Fri

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
          'Practitioner ID',
          'Practitioner',
          'Practitioner group',
          'Profession',

          'DOW',
          'Start time',
          'End time',
          'Duration (hours)',
        ]

        practitioners_query.includes(:business_hours, :groups).load.each do |pract|
          business_hours = pract.business_hours.to_a

          # Use default timeable if user never adjust the settings
          # Mon to Fri are active
          if business_hours.empty?
            WEEKDAYS.each do |dow|
              business_hours.push(
                PractitionerBusinessHour.new(
                  day_of_week: dow,
                  active: true
                )
              )
            end
          end

          business_hours.each do |bh|
            next unless bh.active?

            if bh.availability.present? && bh.availability.is_a?(Array)
              bh.availability.each do |slot|
                duration = nil

                if slot['start'].present? && slot['end'].present?
                  begin
                    start_t = DateTime.strptime(slot['start'], '%H:%M')
                    end_t = DateTime.strptime(slot['end'], '%H:%M')
                    diff_in_secs = end_t > start_t ? (end_t.to_i - start_t.to_i) : 0

                    unless diff_in_secs.zero?
                      duration = (diff_in_secs.to_f / 3600).round(2)
                    end
                  rescue Date::Error
                    # Do nothing
                  end
                end

                csv << [
                  pract.id,
                  pract.full_name,
                  pract.profession.presence,
                  pract.groups.map(&:name).join(', ').presence,

                  dow_name(bh.day_of_week),
                  slot['start'],
                  slot['end'],
                  duration
                ]
              end
            else
              csv << [
                pract.id,
                pract.full_name,
                pract.profession.presence,
                dow_name(bh.day_of_week),
                nil,
                nil,
                nil
              ]
            end
          end
        end
      end
    end

    private

    def practitioners_query
      business.practitioners.active.order(full_name: :asc)
    end

    def dow_name(dow)
      {
        0 => 'Sunday',
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday'
      }[dow]
    end
  end
end
