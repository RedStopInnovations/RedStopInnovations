class RenameAppEventsExtraToData < ActiveRecord::Migration[5.0]
  def change
    rename_column :app_events, :extra, :data

    remove_column :app_events, :ip, :string
    remove_column :app_events, :associated_business_id, :integer
  end
end
