# Mock ActiveRecord model to migrate to a real table later
class Profession
  include ActiveModel::Model
  attr_accessor :name, :slug

  ALL = [
    "Physiotherapist",
    "Podiatrist",
    "Massage Therapist",
    "Chiropractor",
    "Osteopath",
    "Doctor"
  ].map do |name|
    new(
      name: name,
      slug: name.parameterize
    )
  end

  class << self
    def all
      ALL
    end

    def find_by_slug(slug)
      ALL.find { |prof| prof.slug == slug }
    end

    def find_by_name(name)
      ALL.find { |prof| prof.name == name }
    end
  end
end
