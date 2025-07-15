module Settings
  class AvailabilitySubtypesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def index
      @availability_types = AvailabilitySubtype.
        where(business_id: current_business.id).
        not_deleted.
        order(name: :asc).
        to_a
    end

    def show; end

    def create
      @availability_type = AvailabilitySubtype.new(params.require(:availability_subtype).permit(:name))
      @availability_type.business = current_business

      if @availability_type.save
        respond_to do |f|
          f.html do
            redirect_to settings_availability_subtypes_url, notice: 'The item was successfully created.'
          end

          f.json do
            render json: { availability_subtype: @availability_type }
          end
        end
      else
        respond_to do |f|
          f.html {
            flash.now[:alert] = 'Failed to create, please check for form errors.'
            render :new
          }

          f.json do
            render(json: {
              errors: @availability_type.errors.full_messages
            }, status: 422)
          end
        end
      end
    end

    def edit
      @availability_type = AvailabilitySubtype.where(business_id: current_business.id).find(params[:id])
    end

    def update
      @availability_type = AvailabilitySubtype.where(business_id: current_business.id).find(params[:id])

      if @availability_type.update(params.require(:availability_subtype).permit(:name))
        respond_to do |f|
          f.html do
            redirect_to settings_availability_subtypes_url, notice: 'The item was successfully updated.'
          end

          f.json do
            render json: { availability_subtype: @availability_type }
          end
        end
      else
        respond_to do |f|
          f.html {
            flash.now[:alert] = 'Failed to update, please check for form errors.'
            render :new
          }

          f.json do
            render(json: {
              errors: @availability_type.errors.full_messages
            }, status: 422)
          end
        end
      end
    end

    def destroy
      @availability_type = AvailabilitySubtype.where(business_id: current_business.id).find(params[:id])

      @availability_type.update_columns deleted_at: Time.current

      redirect_to settings_availability_subtypes_url,
        notice: 'The item was successfully deleted.'
    end
  end
end
