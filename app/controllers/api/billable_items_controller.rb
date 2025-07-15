module Api
  class BillableItemsController < BaseController
    def index
      @billable_items = current_business
        .billable_items
        .not_deleted
        .order(name: :asc)
        .includes(:tax, :pricing_contacts)
    end

    def show
      @billable_item = current_business.billable_items.find(params[:id])
    end
  end
end
