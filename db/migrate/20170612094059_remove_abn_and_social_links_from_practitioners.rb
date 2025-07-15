class RemoveAbnAndSocialLinksFromPractitioners < ActiveRecord::Migration[5.0]
  def change
    remove_column :practitioners, :abn, :string
    remove_column :practitioners, :abn_document, :string
    remove_column :practitioners, :facebook_url, :string
    remove_column :practitioners, :twitter_url, :string
    remove_column :practitioners, :linkedin_url, :string
    remove_column :practitioners, :youtube_url, :string
  end
end
