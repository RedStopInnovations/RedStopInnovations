class AddMoreColumnsToTreatmentContents < ActiveRecord::Migration[5.0]
  def change
    add_column :treatment_contents, :sname, 	:string
    add_column :treatment_contents, :sorder, 	:integer
    add_column :treatment_contents, :qname, 	:string
    add_column :treatment_contents, :qtype, 	:integer
    add_column :treatment_contents, :qorder, 	:integer
  end
end
