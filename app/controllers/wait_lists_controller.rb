class WaitListsController < ApplicationController
  include HasABusiness

  def print
    @filter = parse_wait_list_filter
    searcher = WaitListSearch::Searcher.new(
      business: current_business,
      filter: @filter
    )

    @wait_lists = searcher.result
    render layout: false
  end

  def destroy
    wait_list = current_business.wait_lists.find(params[:id])
    wait_list.destroy
    flash[:notice] = 'The waiting list has been successfully updated.'
    redirect_back fallback_location: appointments_patient_url(wait_list.patient)
  end

  def mark_scheduled
    wait_list = current_business.wait_lists.find(params[:id])
    wait_list.update!(scheduled: true)
    flash[:notice] = 'The waiting list has been successfully updated.'
    redirect_back fallback_location: appointments_patient_url(wait_list.patient)
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

    filter
  end
end
