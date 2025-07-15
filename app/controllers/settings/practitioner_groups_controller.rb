module Settings
  class PractitionerGroupsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    before_action :set_group, only: [:destroy, :edit, :show, :update]

    def index
      @groups = current_business.groups.order(name: :asc).page(params[:page])
    end

    def new
      @group = current_business.groups.new
      @group.practitioners.build
    end

    def show; end

    def create
      @group = current_business.groups.new group_params
      if @group.save
        redirect_to settings_practitioner_group_url(@group),
                    notice: 'Group was successfully created.'
      else
        flash.now[:alert] = 'Failed to create group. Please check for form errors.'
        render :new
      end
    end

    def edit
    end

    def update
      if @group.update(group_params)
        redirect_to settings_practitioner_group_url(@group),
                    notice: 'Group was successfully updated.'
      else
        flash.now[:alert] = 'Failed to update group. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @group.destroy
      redirect_to settings_practitioner_groups_path,
        notice: 'Group was successfully deleted.'
    end

    private

    def group_params
      params.require(:group).permit(:name, :description, practitioner_ids: [])
    end

    def set_group
      @group = current_business.groups.find params[:id]
    end
  end
end
