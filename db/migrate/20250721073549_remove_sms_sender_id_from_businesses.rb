class RemoveSmsSenderIdFromBusinesses < ActiveRecord::Migration[7.1]
  def change
    remove_column :business_settings, :sms_sender_id, :string
  end
end
