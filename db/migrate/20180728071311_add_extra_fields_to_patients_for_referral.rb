class AddExtraFieldsToPatientsForReferral < ActiveRecord::Migration[5.0]
  def change
    change_table :patients do |t|
      t.string :nationality
      t.string :aboriginal_status
      t.string :spoken_languages
      t.jsonb :ndis_details, default: {} # NDIS
      t.jsonb :hcp_details, default: {}  # Home care package
      t.jsonb :hih_details, default: {}  # Hospital in the home
      t.jsonb :hi_details, default: {}  # Health insurance
    end
  end
end
