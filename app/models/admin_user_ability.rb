class AdminUserAbility
  include CanCan::Ability

  def initialize(admin_user)
    admin_user ||= AdminUser.new

    if admin_user.persisted?
      if admin_user.is_super_admin?
        can :manage, :all
      end
    end
  end
end
