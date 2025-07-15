module HasMarketplaceScope
  extend ActiveSupport::Concern

  included do
    scope :within_marketplace, -> (marketplace_id) {
      joins(business: [:marketplace]).
      where(marketplaces: { id: marketplace_id})
    }
  end
end
