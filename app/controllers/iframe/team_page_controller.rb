module Iframe
  class TeamPageController < BaseController
    layout 'frontend/layouts/minimal'

    def team
      @business = Business.find params[:business_id]
      @available_professions = @business.practitioners.active.where("profession <> ''").pluck(:profession).uniq

      @practitioners = practitioners_query(@business)
    end

    def single
      @business = Business.find params[:business_id]

      @practitioner = @business.practitioners.active.find params[:practitioner_id]
    end

    private

    def practitioners_query(business)
      query = business.practitioners.active.includes(:user, :business)

      if params[:profession].present?
        query = query.where(profession: params[:profession])
      end

      if params[:location].present?
        loc_coords = Geocoder.coordinates "#{params[:location]}, #{current_country}"
        query = query.near(loc_coords, 50, unit: :km)
      end

      query.
        joins(:user).
        order(rating_score: :desc).
        order(
          Arel.sql('CASE WHEN users.avatar_file_name IS NOT NULL THEN 0 ELSE 1 END ASC, practitioners.last_name ASC')
        )
    end
  end
end