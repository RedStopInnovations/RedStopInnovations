class UpdateMyprofileService
  attr_reader :user, :form

  def call(target_user, form)
    @user = target_user
    @form = form

    ApplicationRecord.transaction do
      user.assign_attributes(user_attributes)
      user.save!(validate: false)

      if user.is_practitioner? && user.practitioner
        practitioner = user.practitioner
        practitioner.assign_attributes(
          practitioner_attributes.merge(
            business_id: user.business_id,
            user_id: user.id,
            full_name: user.full_name,
            first_name: user.first_name,
            last_name: user.last_name,
          )
        )
        practitioner.active = true
        if practitioner.slug.blank? || practitioner.first_name_changed? || practitioner.last_name_changed?
          practitioner.slug = practitioner.generate_slug
        end
        practitioner.save!(validate: false)
      end
    end
  end

  private

  def user_attributes
    attrs = form.attributes.slice(
      :first_name,
      :last_name,
      :email,
      :timezone
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
      :education
    )
    attrs
  end
end
