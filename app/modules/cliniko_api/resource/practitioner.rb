module ClinikoApi
  module Resource
    class Practitioner < Base
      attribute :id, String
      attribute :title, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :label, String
      attribute :display_name, String
      attribute :designation, String
      attribute :description, String
      attribute :created_at, DateTime
      attribute :updated_at, DateTime
      attribute :user, Hash
    end
  end
end
