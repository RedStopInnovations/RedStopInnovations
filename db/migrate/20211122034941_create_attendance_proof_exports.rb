class CreateAttendanceProofExports < ActiveRecord::Migration[5.2]
  def change
    create_table :attendance_proof_exports do |t|
      t.integer :business_id, nil: false, index: true
      t.integer :author_id, nil: false, index: true
      t.json :options
      t.text :description
      t.string :status, nil: false
      t.timestamps
    end
  end
end
