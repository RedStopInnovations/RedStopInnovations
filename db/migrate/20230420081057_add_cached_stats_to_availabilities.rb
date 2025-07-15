class AddCachedStatsToAvailabilities < ActiveRecord::Migration[7.0]
  def change
    add_column :availabilities, :cached_stats, :jsonb, default: {}
    add_column :availabilities, :cached_stats_updated_at, :datetime
  end
end
