class CreateCpdCertificates < ActiveRecord::Migration[5.0]
  def change
    create_table :cpd_certificates do |t|
      t.integer :course_id
      t.string :course_title
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :profession, null: false
      t.string :email, null: false
      t.string :course_duration, null: false
      t.text :course_reflection
      t.string :cpd_points, null: false

      t.index :email
      t.index :course_id

      t.timestamps
    end
  end
end
