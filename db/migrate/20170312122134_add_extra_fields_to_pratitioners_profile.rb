class AddExtraFieldsToPratitionersProfile < ActiveRecord::Migration[5.0]
  def change
    change_table :practitioners do |t|
      t.text :summary
      t.string :education
      t.text :service_description
      t.text :availability
    end
  end
end
