module App
  class MyPreferencesController < ApplicationController
    include HasABusiness

    def update
      pref = current_user.preferences.find_or_initialize_by(key: params[:key])
      pref.value = params[:value].to_s

      if pref.valid?
        if params[:value].blank?
          pref.delete
        else
          pref.save
        end
      end

      head 200
    end
  end
end