class AddGoogleTagManagerToBusinessSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :business_settings, :google_tag_manager, :json, default: {}
  end
end
