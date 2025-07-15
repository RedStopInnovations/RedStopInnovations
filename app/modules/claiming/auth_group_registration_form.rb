module Claiming
  class AuthGroupRegistrationForm
    include Virtus.model
    include ActiveModel::Model

    attribute :name, String
    attribute :practitioner_ids, [Integer]

    validates_presence_of :name

    def self.build_from_business(business)
      new(
        name: business.name
      )
    end
  end
end
