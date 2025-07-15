class AddSmsSenderIdToBusinessSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :business_settings, :sms_sender_id, :string
  end
end
