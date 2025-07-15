class CreateUserService
  attr_reader :business, :current_user, :form

  def call(business, current_user, form)
    @business = business
    @current_user = current_user
    @form = form

    user = User.new(user_attributes)
    user.business = business

    result = OpenStruct.new(success: true)

    ApplicationRecord.transaction do
      if form.send_invitation_email?
        user.password = Devise.friendly_token.first(8)
      else
        user.password = form.password
      end

      user.save!(validate: false)

      if user.is_practitioner?
        practitioner = Practitioner.new(practitioner_attributes)
        practitioner.assign_attributes(
          business_id: business.id,
          user_id: user.id,
          full_name: user.full_name,
          first_name: user.first_name,
          last_name: user.last_name,
        )
        practitioner.save!(validate: false)
        practitioner.update_column :slug, practitioner.generate_slug
      end

      if form.send_invitation_email?
        user.invite!(current_user)
      end
    end

    result.user = user

    result
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

    if form.avatar_data_url.present?
      parsed_img_data = Utils::Image.parse_from_data_url(form.avatar_data_url)

      if parsed_img_data
        generated_file_name = "#{Time.current.to_i}.#{parsed_img_data[:extension]}"
        tmp_file = Extensions::FakeFileIo.new(
          generated_file_name,
          Base64.decode64(parsed_img_data[:data])
        )
        attrs[:avatar] = tmp_file
      end
    end

    attrs[:full_name] = [attrs[:first_name], attrs[:last_name]].compact.join(' ').strip

    if attrs[:timezone].blank?
      attrs[:timezone] = current_user.timezone
    end

    attrs
  end

  def practitioner_attributes
    form.attributes.slice(
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
  end
end
