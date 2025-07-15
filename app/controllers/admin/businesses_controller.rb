module Admin
  class BusinessesController < BaseController
    before_action :set_business, only: [:show, :edit, :update, :approve, :suspend]

    before_action do
      authorize! :manage, Business
    end

    def index
      @search_query = Business.order(id: :desc)

      if params[:has_credit_card].present?
        @search_query = @search_query.joins(:subscription)
        if params[:has_credit_card].to_s == '1'
          @search_query = @search_query.where('subscriptions.stripe_customer_id IS NOT NULL')
        elsif params[:has_credit_card].to_s == '0'
          @search_query = @search_query.where('subscriptions.stripe_customer_id IS NULL')
        end
      end

      if params[:is_approved].present?
        if params[:is_approved].to_s == '1'
          @search_query = @search_query.where(active: true)
        elsif params[:is_approved].to_s == '0'
          @search_query = @search_query.where(active: false)
        end
      end

      if params[:is_suspended].present?
        if params[:is_suspended].to_s == '1'
          @search_query = @search_query.where(suspended: true)
        elsif params[:is_suspended].to_s == '0'
          @search_query = @search_query.where(suspended: false)
        end
      end

      if params[:min_age].present?
        @search_query = @search_query.where('businesses.created_at < ?', params[:min_age].to_i.days.ago)
      end

      @search_query = @search_query.ransack(params[:q].try(:to_unsafe_h))

      respond_to do |format|
        format.html {
          @businesses = @search_query.result
                                    .order(id: :desc)
                                    .preload(:subscription)
                                    .page(params[:page])
                                    .per(50)
        }
        format.csv {
          @businesses = @search_query.result.order(id: :desc)
          send_data make_businesses_csv_export(@businesses)
        }
      end
    end

    def show
    end

    def edit
    end

    def update
      if @business.update(business_params)
        redirect_to admin_business_url(@business), notice: 'Business was successfully updated.'
      else
        render :edit
      end
    end

    def approve
      @business.update(active: !@business.active)
      redirect_back fallback_location: admin_business_url(@business),
                    notice: 'Business was successfully updated.'
    end

    def suspend
      @business.update_columns(suspended: !@business.suspended)

      if @business.suspended?
        AdminMailer.business_suspended_confirmation(@business).deliver_later
      else
        AdminMailer.business_unsuspended_confirmation(@business).deliver_later
      end

      redirect_back fallback_location: admin_business_url(@business),
                    notice: 'The business was suspended.'
    end

    def bulk_approve
      Business.where(active: false).where(id: params[:business_ids]).update_all(active: true)
      redirect_to admin_businesses_url, notice: 'Businesses was successfully approved.'
    end

    def bulk_suspend
      Business.where(suspended: false).where(id: params[:business_ids]).update_all(suspended: true)
      redirect_to admin_businesses_url, notice: 'Businesses was successfully suspended.'
    end

    private

    def set_business
      @business = Business.find(params[:id])
    end

    def business_params
      params.require(:business).permit(
        :name,
        :phone,
        :mobile,
        :website,
        :fax,
        :email,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :is_partner
      )
    end

    def make_businesses_csv_export(businesses)
      CSV.generate(headers: true) do |csv|
        csv << [
          'Name',
          'Phone',
          'Mobile',
          'Email',
          'Address',
          'State',
          'Professions'
        ]
        # FIXME: practitioners N+1 query
        businesses.each do |b|
          professions = b.practitioners.active.pluck(:profession).uniq
          csv << [
            b.name,
            b.phone,
            b.mobile,
            b.email,
            b.short_address,
            b.state,
            professions.join(', ')
          ]
        end
      end
    end
  end
end
