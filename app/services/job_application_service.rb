class JobApplicationService
  attr_reader :form

  # @param form JobApplicationForm
  def call(form)
    @form = form
    business = nil
    user = nil

    ActiveRecord::Base.transaction do
      business = Business.create!(build_business_attributes)

      user = User.create!(
        build_user_attributes.merge(
          business_id: business.id
        )
      )

      practitioner = business.practitioners.create!(
        build_practitioner_attributes.merge(
          user_id: user.id
        )
      )

      practitioner.update_column :slug, practitioner.generate_slug
    end

    if business
      CreateBusinessDefaultDataService.new.call(business)
      CreateSubscription.new.call(
        SubscriptionPlan.find_by!(name: 'private').id,
        business.id
      )
    end

    if user
      send_notification_emails(user)
    end

    user
  end

  private

  def user_full_name
    "#{ form.first_name.strip } #{ form.last_name.strip }"
  end

  def build_business_attributes
    business_name = "#{ user_full_name } #{ form.profession }"
    attrs = {
      name: business_name,
      abn: form.abn,
      email: form.email,
      mobile: form.mobile
    }
    %i[address1 city state postcode country].each do |k|
      attrs[k] = form.send(k)
    end

    attrs
  end

  def build_practitioner_attributes
    attrs = {
      first_name: form.first_name,
      last_name: form.last_name,
      full_name: user_full_name,
      medicare: form.medicare,
      email: form.email,
      summary: form.summary,
      profession: form.profession,
      mobile: form.mobile,
      education: "Bachelor of #{ form.profession }"
    }

    %i[address1 city state postcode country].each do |k|
      attrs[k] = form.send(k)
    end

    attrs
  end

  def build_user_attributes
    attrs = {
      first_name: form.first_name,
      last_name: form.last_name,
      full_name: user_full_name,
      email: form.email,
      password: form.password,
      is_practitioner: true,
      role: User::ADMINISTRATOR_ROLE
    }

    attrs
  end

  def send_notification_emails(user)
    UserMailer.welcome(user).deliver_later
    AdminMailer.new_user(user).deliver_later
  end
end
