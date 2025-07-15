class TaxesController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, Tax
  end

  def index
    @taxes = current_business.taxes.all
  end

  def show
    @tax = current_business.taxes.find params[:id]
  end

  def new
    @tax = Tax.new
  end

  def create
    @tax = current_business.taxes.new tax_params
    if @tax.save
      redirect_to tax_path(@tax),
                  notice: 'Tax was successfully created.'
    else
      render :new
    end
  end

  def edit
    @tax = current_business.taxes.find params[:id]
  end

  def update
    @tax = current_business.taxes.find params[:id]
    if @tax.update tax_params
      redirect_to tax_path(@tax),
                  notice: 'Tax was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    tax = current_business.taxes.find params[:id]
    tax.destroy
    redirect_to taxes_path, notice: 'Tax was successfully deleted.'
  end

  private

  def tax_params
    params.require(:tax).permit(:name, :rate)
  end
end
