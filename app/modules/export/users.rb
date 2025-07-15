module Export
  class Users
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
          'ID',
          'First name',
          'Last name',
          'Email',
          'Role',
          'Employee number',
          'Active',
          'Is practitioner',
          'Profession',
          'Provider number',
          'City',
          'State',
          'Postcode',
          'Last login',
          '2FA authentication',
          'Creation',
        ]

        users_query.load.each do |user|
          pract = user.is_practitioner? ? user.practitioner : nil

          csv << [
            user.id,
            user.first_name,
            user.last_name,
            user.email,
            user.role.titleize,
            user.employee_number,
            user.active? ? 'Yes' : 'No',
            user.is_practitioner? ? 'Yes' : 'No',

            pract&.profession,
            pract&.medicare,
            pract&.city,
            pract&.state,
            pract&.postcode,

            user.current_sign_in_at? ? user.current_sign_in_at.strftime('%Y-%m-%d') : nil,
            user.enable_google_authenticator? ? 'Yes' : 'No' ,
            user.created_at.strftime('%Y-%m-%d')
          ]
        end
      end
    end

    private

    def users_query
      business.users.order(full_name: :asc)
    end
  end
end
