class AlterClinikoRecordsPatientIdSize < ActiveRecord::Migration[5.2]
  def change
    change_column :cliniko_records, :reference_id, :bigint # Id in Cliniko
    change_column :cliniko_records, :internal_id, :bigint
  end
end
