class BillableItemsController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, BillableItem
  end

  before_action :set_billable_item, only: [:show, :edit, :update, :destroy]

  def index
    @search_query = current_business.billable_items.not_deleted.ransack(params[:q].try(:to_unsafe_h))

    @billable_items = @search_query.result
    .order(name: :asc)
    .page(params[:page])
  end

  def show
  end

  def new
    @billable_item = BillableItem.new
    @billable_item.pricing_contacts.build
  end

  def edit
  end

  def create
    @billable_item = current_business.billable_items.new(billable_item_params)

    if @billable_item.save
      redirect_to billable_items_url,
                  notice: 'The billable item was successfully created.'
    else
      flash.now[:alert] = 'Failed to create billable item. Please check for form errors.'
      render :new
    end
  end

  def update
    if @billable_item.update(billable_item_params)
      @billable_item.pricing_contacts.delete_all unless @billable_item.pricing_for_contact

      redirect_to billable_items_url,
                  notice: 'The billable item was successfully updated.'
    else
      flash.now[:alert] = 'Failed to update billable item. Please check for form errors.'
      render :edit
    end
  end

  def destroy
    DeletedResource.create(
      business: current_business,
      resource: @billable_item,
      author: current_user,
      deleted_at: Time.current
    )
    @billable_item.update_column(:deleted_at, Time.current)
    redirect_to billable_items_url,
                notice: 'The billable item was successfully archived.'
  end

  private

  def set_billable_item
    @billable_item = current_business.billable_items.find(params[:id])
  end

  def billable_item_params
    result = params.require(:billable_item).permit(
      :name,
      :description,
      :item_number,
      :price,
      :health_insurance_rebate,
      :tax_id,
      :pricing_for_contact,
      :display_on_pricing_page,
      practitioner_ids: [],
      pricing_contacts_attributes: [:id, :contact_id, :price, :_destroy]
    )

    result.expect(:pricing_contacts_attributes) unless result[:pricing_for_contact]
    result
  end
end
