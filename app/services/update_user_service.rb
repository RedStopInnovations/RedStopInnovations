class UpdateUserService
  attr_reader :business, :user, :form

  def call(business, target_user, form)
    @business = business
    @user = target_user
    @form = form

    ApplicationRecord.transaction do
      user.assign_attributes(user_attributes)
      user.save!(validate: false)

      if user.is_practitioner?
        practitioner = user.practitioner
        if practitioner.nil?
          practitioner = Practitioner.new
        end

        practitioner.assign_attributes(
          practitioner_attributes.merge(
            business_id: business.id,
            user_id: user.id,
            full_name: user.full_name,
            first_name: user.first_name,
            last_name: user.last_name
          )
        )

        practitioner.active = user.active?

        need_generate_slug = practitioner.slug.blank? || practitioner.first_name_changed? || practitioner.last_name_changed?
        practitioner.save!(validate: false)

        if need_generate_slug
          practitioner.update_column :slug, practitioner.generate_slug
        end
      else
        if user.practitioner
          user.practitioner.update_column :active, false
        end
      end
    end
  end

  private

  def user_attributes
    attrs = form.attributes.slice(
      :first_name,
      :last_name,
      :email,
      :timezone,
      :is_practitioner,
      :active,
      :role,
      :employee_number
    )

    attrs[:full_name] = [attrs[:first_name], attrs[:last_name]].compact.join(' ').strip

    attrs
  end

  def practitioner_attributes
    attrs = form.attributes.slice(
      :profession,
      :medicare,
      :phone,
      :mobile,
      :address1,
      :address2,
      :city,
      :state,
      :postcode,
      :country,
      :summary,
      :education,
      :allow_online_bookings
    )
    attrs
  end
end
