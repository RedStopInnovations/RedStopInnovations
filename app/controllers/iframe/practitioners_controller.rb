module Iframe
  class PractitionersController < BaseController
    def team
      @business = Business.find_by id: params[:id]
      @pagination = false
      if @business
        query = @business.practitioners.active

        practitioner_ids = params[:practitioner_ids].to_s.split(",")

        if params[:practitioner_ids].present?
          query = query.where(id: practitioner_ids)
        end

        if practitioner_ids.length > 20 || practitioner_ids.blank?
          @pagination = true
          query = query.page(params[:page]).per(params[:per])
        end
        @practitioners = query
      end
    end

    def single
      @practitioner = Practitioner.active.find_by id: params[:id]
    end
  end
end
