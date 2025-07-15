module Admin
  class AdminOverviewReport
    attr_reader :all_users_count,
                :active_users_count,
                :active_practitioners_count,
                :activity_last_30_days_users_count

    def initialize
      @all_users_count = User.count
      @active_users_count = User.active.count
      @active_practitioners_count = User.active.where(is_practitioner: true).count
      @activity_last_30_days_users_count = User.where('current_sign_in_at > ?', 30.days.ago).count
    end
  end
end