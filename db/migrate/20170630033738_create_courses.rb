class CreateCourses < ActiveRecord::Migration[5.0]
  def change
    create_table :courses do |t|
      t.string :title
      t.text :video_url
      t.string :presenter_full_name
      t.string :course_duration
      t.string :cpd_points
      t.text :description
      t.text :reflection_answer
      t.text :profession_tags
      t.string :seo_page_title
      t.text :seo_description
      t.text :seo_metatags

      t.timestamps
    end
  end
end
