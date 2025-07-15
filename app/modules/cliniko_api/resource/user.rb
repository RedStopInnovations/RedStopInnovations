module ClinikoApi
  module Resource
    class User < Base
      attribute :id, String
      attribute :title, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :email, String
      attribute :role, String
      attribute :time_zone, String
      attribute :user_active, Boolean
      attribute :created_at, DateTime
      attribute :updated_at, DateTime
    end
  end
end
