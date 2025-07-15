class AddMoreColumnsToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :name, 					:string
    add_column :treatments, :print_name, 		:string
    add_column :treatments, :print_address, :boolean, default: false
    add_column :treatments, :print_birth, 	:boolean, default: false
    add_column :treatments, :print_ref_num, :boolean, default: false
    add_column :treatments, :print_doctor, 	:boolean, default: false
  end
end
