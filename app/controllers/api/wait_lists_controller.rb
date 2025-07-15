module Api
  class WaitListsController < BaseController
    def index
      searcher = WaitListSearch::Searcher.new(
        business: current_business,
        filter: parse_wait_list_filter
      )

      @wait_lists = searcher.result.page(params[:page]).per(10)
    end

    def show
      @wait_list = current_business.wait_lists.find(params[:id])
    end

    def create
      form = CreateWaitListForm.new(create_params.merge(business: current_business))
      if form.valid?
        result = CreateWaitListService.new.call(current_business, form)
        if result.success
          @wait_list = result.wait_list
          render :show
        else
          render status: 500
        end
      else
        render(
          json: {
            errors: form.errors.full_messages
          },
          status: 422
        )
      end
    end

    def update
      form = UpdateWaitListForm.new(update_prams.merge(business: current_business))
      @wait_list = current_business.wait_lists.find(params[:id])

      if form.valid?
        UpdateWaitListService.new.call(@wait_list, form)
        @wait_list.reload
        render :show
      else
        render(
          json: {
            errors: form.errors.full_messages
          },
          status: 422
        )
      end
    end

    def destroy
      wait_list = current_business.wait_lists.find(params[:id])
      WaitList.transaction do
        wait_list.destroy
        if wait_list.repeat_group_uid? && params[:delete_repeats] == true
          wait_list.repeat_group_uid?
          WaitList.where(repeat_group_uid: wait_list.repeat_group_uid).
            where('id <> ?', wait_list.id).
            destroy_all
        end
      end

      head :no_content
    end

    def mark_scheduled
      @wait_list = current_business.wait_lists.find(params[:id])
      @wait_list.update!(scheduled: true)
      render :show
    end

    private

    def parse_wait_list_filter
      filter = WaitListSearch::Filter.new

      if params.key?(:patient_search)
        filter.patient_search = params[:patient_search].to_s
      end

      if params.key?(:location_search)
        filter.location_search = params[:location_search].to_s
      end

      if params.key?(:profession)
        filter.profession = params[:profession].to_s
      end

      if params.key?(:appointment_type_id)
        filter.appointment_type_id = params[:appointment_type_id]
      end

      if params.key?(:practitioner_id)
        filter.practitioner_id = params[:practitioner_id]
      end

      filter
    end

    def create_params
      params.require(:wait_list).permit(
        :patient_id,
        :practitioner_id,
        :appointment_type_id,
        :profession,
        :date,
        :repeat_type,
        :repeat_frequency,
        :repeats_total,
        :notes
      )
    end

    def update_prams
      params.require(:wait_list).permit(
        :patient_id,
        :practitioner_id,
        :appointment_type_id,
        :profession,
        :date,
        :apply_to_repeats,
        :notes
      )
    end
  end
end
