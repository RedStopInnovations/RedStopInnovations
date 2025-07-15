# Virtual ActiveRecord model for availability type
class AvailabilityType
  include ActiveModel::Model
  attr_accessor :id, :name, :uid

  TYPE_IDS = [
    TYPE_HOME_VISIT_ID   = 1,
    TYPE_TELEHEALTH_ID   = 2,
    TYPE_FACILITY_ID     = 4,
    TYPE_NON_BILLABLE_ID = 5,
    TYPE_GROUP_APPOINTMENT_ID = 6,
  ].freeze

  ALL = [
    {
      id: TYPE_HOME_VISIT_ID,
      uid: 'HOME_VISIT',
      name: 'Home visit'
    },
    {
      id: TYPE_TELEHEALTH_ID,
      uid: 'TELEHEALTH',
      name: 'Telehealth'
    },
    {
      id: TYPE_FACILITY_ID,
      uid: 'FACILITY',
      name: 'Facility'
    },
    {
      id: TYPE_NON_BILLABLE_ID,
      uid: 'NON_BILLABLE',
      name: 'Non-billable'
    },
    {
      id: TYPE_GROUP_APPOINTMENT_ID,
      uid: 'GROUP_APPOINTMENT',
      name: 'Group appointment'
    }
  ].freeze

  class << self
    def all
      ALL.map do |at_attrs|
        new(at_attrs)
      end
    end

    # Find by id or name
    def [](id_or_name)
      case id_or_name
      when Integer
        find_by_id(id_or_name)
      when String
        find_by_name(id_or_name)
      else
        nil
      end
    end

    def find_by_id(id)
      att_attrs = ALL.find { |at_attrs| at_attrs[:id] == id }
      new(att_attrs) if att_attrs
    end

    def find_by_uid(uid)
      att_attrs = ALL.find { |at_attrs| at_attrs[:uid] == uid }
      new(att_attrs) if att_attrs
    end

    def find_by_name(name)
      att_attrs = ALL.find { |at_attrs| at_attrs[:name] == name }
      new(att_attrs) if att_attrs
    end
  end

  def <=>(another)
    another.id == id
  end
end
