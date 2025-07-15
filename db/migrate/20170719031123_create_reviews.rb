class CreateReviews < ActiveRecord::Migration[5.0]
  def change
    create_table :reviews do |t|
      t.references :practitioner
      t.references :patient
      t.integer :rating
      t.text :comment
      t.boolean :publish_rating, default: true
      t.boolean :publish_comment, default: true
      t.boolean :approved, default: false

      t.timestamps
    end
  end
end
