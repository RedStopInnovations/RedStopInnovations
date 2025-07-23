class AddMoreToCommunications < ActiveRecord::Migration[7.1]
  def change
    change_table :communications do |t|
      t.string :subject # Email subject
      t.string :from
    end

    remove_column :communications, :content # content is not used.
    remove_column :communications, :patient_id # legacy implememntation, now using recipient polymorphic association.
    remove_column :communications, :contact_id # legacy implememntation, now using recipient polymorphic association.
    remove_column :communications, :practitioner_id # legacy implememntation
  end
end
