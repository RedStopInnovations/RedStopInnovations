class App::ConversationsController < ApplicationController
  def create
    url = params[:url].to_s

    if url.start_with?('/')
      room = current_business.conversations.find_or_create_by url: url
      # @TODO: missing validations
      message = room.messages.new(
        content: params[:content].to_s,
        user_id: current_user.id
      )

      message.save!
      redirect_back fallback_location: dashboard_path, notice: 'Comment has been saved successfully'
    else

      redirect_back fallback_location: dashboard_path, alert: 'Invalid request'
    end
  end
end