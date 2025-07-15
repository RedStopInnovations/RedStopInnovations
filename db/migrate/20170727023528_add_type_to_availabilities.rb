class AddTypeToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    change_table :availabilities do |t|
      t.integer :availability_type_id
      t.index [:business_id, :availability_type_id], name: 'index_business_id_and_availability_type_id'
      t.index [:practitioner_id, :availability_type_id], name: 'index_practitioner_id_and_availability_type_id'
    end
  end
end
