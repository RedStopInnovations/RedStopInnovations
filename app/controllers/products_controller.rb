class ProductsController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, Product
  end

  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @products = current_business.products.not_deleted.order(name: :asc).page(params[:page])
  end

  def show
  end

  def new
    @product = Product.new
  end

  def edit
  end

  def create
    @product = current_business.products.new(product_params)

    if @product.save
      redirect_to product_url(@product), notice: 'Product was successfully created.'
    else
      flash.now[:alert] = 'Failed to create product. Please check for form errors.'
      render :new
    end
  end

  def update
    if @product.update(product_params)
      redirect_to product_url(@product), notice: 'Product was successfully updated.'
    else
      flash.now[:alert] = 'Failed to update product. Please check for form errors.'
      render :edit
    end
  end

  def destroy
    DeletedResource.create(
      business: current_business,
      resource: @product,
      author: current_user,
      deleted_at: Time.current
    )
    @product.update_column(:deleted_at, Time.current)
    flash[:notice] = 'The product was successfully archived.'
    redirect_to products_url
  end

  private

  def set_product
    @product = current_business.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name,
      :item_code,
      :serial_number,
      :price,
      :supplier_name,
      :supplier_phone,
      :supplier_email,
      :notes,
      :image,
      :tax_id
    )
  end
end
