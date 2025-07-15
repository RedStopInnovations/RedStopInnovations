class RegistrationService
  # @param form RegistrationForm
  def call(form)
    user = nil
    business = nil

    ActiveRecord::Base.transaction do
      plan_id = SubscriptionPlan.find_by!(name: 'Private').id

      business = Business.create!(
        name: form.business_name,
        email: form.email,
        country: form.country
      )

      user_full_name = [form.first_name, form.last_name].compact.join(' ').strip

      user = User.create!(
        first_name: form.first_name,
        last_name: form.last_name,
        full_name: user_full_name,
        timezone: form.timezone,
        email: form.email,
        password: form.password,
        business_id: business.id,
        is_practitioner: true,
        role: User::ADMINISTRATOR_ROLE
      )

      practitioner = Practitioner.create!(
        business_id: business.id,
        user_id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        email: user.email,
        country: form.country
      )

      practitioner.update_column :slug, practitioner.generate_slug

      CreateSubscription.new.call(
        plan_id,
        business.id
      )
    end

    CreateBusinessDefaultDataService.new.call(business) if business

    user
  end
end
