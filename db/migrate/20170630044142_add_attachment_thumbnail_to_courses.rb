class AddAttachmentThumbnailToCourses < ActiveRecord::Migration[5.0]
  def self.up
    change_table :courses do |t|
      t.attachment :thumbnail
    end
  end

  def self.down
    remove_attachment :courses, :thumbnail
  end
end
