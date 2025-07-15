class AddAvgRatingScoreToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :rating_score, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
