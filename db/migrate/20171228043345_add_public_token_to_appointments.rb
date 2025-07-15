class AddPublicTokenToAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :public_token, :string
  end
end
