module Admin
  class PractitionersController < BaseController
    before_action do
      authorize! :manage, Practitioner
    end
    before_action :set_practitioner, only: [:show, :edit, :update, :approval, :delete_avatar]

    def index
      @search_query =  Practitioner.joins(:user)
                                   .includes(:business)
                                   .where(users: { is_practitioner: true })

      @search_query = @search_query.where(active: :true) unless params[:include_inactive].present?

      if params[:has_photo]
        if params[:has_photo].to_s == '1'
          @search_query = @search_query.where('users.avatar_file_name IS NOT NULL')
        elsif params[:has_photo].to_s == '0'
          @search_query = @search_query.where('users.avatar_file_name IS NULL')
        end
      end

      if params[:is_approved]
        if params[:is_approved].to_s == '1'
          @search_query = @search_query.where(approved: true)
        elsif params[:is_approved].to_s == '0'
          @search_query = @search_query.where(approved: false)
        end
      end

      if params[:is_public_profile]
        if params[:is_public_profile].to_s == '1'
          @search_query = @search_query.where(public_profile: true)
        elsif params[:is_public_profile].to_s == '0'
          @search_query = @search_query.where(public_profile: false)
        end
      end

      @search_query = @search_query.ransack(params[:q].try(:to_unsafe_h))

      respond_to do |format|
        format.html {
          @practitioners = @search_query.result
                                        .order(id: :desc)
                                        .page(params[:page])
        }
        format.csv {
          @practitioners = @search_query.result.order(id: :desc)
          send_data make_practitioners_csv_export(@practitioners)
        }
      end
    end

    def show; end

    def edit
      @user = @practitioner.user
    end

    def update
      @user = @practitioner.user
      email_was = @practitioner.user_email

      if @user.update(update_params)
        redirect_to admin_practitioner_url(@practitioner),
                    notice: 'The practitioner profile has been updated.'
      else
        flash.now[:alert] = 'Failed to update the practitioner profile.'\
                            ' Please check for form errors.'
        render :edit
      end
    end

    def approval
      approved_was = @practitioner.approved?
      @practitioner.update_columns(approved: !@practitioner.approved?)

      flash[:notice] = 'Practitioner profile was successfully updated'
      redirect_back fallback_location: admin_practitioner_url(@practitioner)
    end

    def bulk_approve_profile
      flash[:notice] = 'Practitioners profile was successfully approved'
      Practitioner.where(id: params[:practitioner_ids]).update_all(
        approved: true
      )
      redirect_back fallback_location: admin_practitioners_url
    end

    def bulk_reject_profile
      flash[:notice] = 'Practitioners profile was successfully rejected'
      Practitioner.where(id: params[:practitioner_ids]).update_all(
        approved: false
      )
      redirect_back fallback_location: admin_practitioners_url
    end

    def delete_avatar
      user = @practitioner.user
      user.avatar = nil
      user.save!(validate: false)

      redirect_back fallback_location: admin_practitioner_url(@practitioner)
    end

    private

    def set_practitioner
      @practitioner = Practitioner.find params[:id]
    end

    def update_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        practitioner_attributes: [
          :id,
          :public_profile,
          :profession,
          :phone,
          :email,
          :mobile,
          :address1,
          :address2,
          :city,
          :state,
          :postcode,
          :country,
          :website,
          :summary,
          :education,
          :availability,
          :approved,
          :sms_reminder_enabled,
          :allow_online_bookings,
          tag_ids: []
        ]
      )
    end

    def make_practitioners_csv_export(practitioners)
      CSV.generate(headers: true) do |csv|
        csv << [
          'First name',
          'Last name',
          'Mobile',
          'Phone',
          'Email',
          'Profession',
          'Address',
          'State'
        ]

        practitioners.each do |p|
          csv << [
            p.first_name,
            p.last_name,
            p.mobile,
            p.phone,
            p.email,
            p.profession,
            p.short_address,
            p.state,
          ]
        end
      end
    end
  end
end
