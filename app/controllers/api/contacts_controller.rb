module Api
  class ContactsController < BaseController
    def search
      keyword = params[:s].to_s.presence

      @contacts =
        if keyword
          current_business.contacts.
            ransack(business_name_or_full_name_cont: keyword).
            result.
            limit(params[:limit] || 25).
            order(business_name: :asc)
        else
          []
        end
    end

    def show
      @contact = current_business.contacts.with_deleted.find(params[:id])
    end
  end
end
