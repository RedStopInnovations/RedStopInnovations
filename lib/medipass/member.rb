module Medipass
  class Member
    attr_reader :id, :first_name, :last_name, :email, :dob, :mobile

    # @see: https://developers.medipass.io/docs?v=2#discovering-members
    def self.discovery(params)
      Medipass.api_call(:get, '/discovery/members', params)
    end
  end
end
