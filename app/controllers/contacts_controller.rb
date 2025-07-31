class ContactsController < ApplicationController
  include HasABusiness

  before_action :set_contact, only: [
    :show, :edit, :update, :archive, :destroy, :invoices, :patients,
    :possible_duplicates, :merge,
    :update_important_notification
  ]

  def index
    authorize! :read, Contact

    @ransack_params = params[:q].try(:to_unsafe_h) || {}

    main_keyword = @ransack_params[:first_name_or_last_name_or_full_name_or_business_name_or_email_or_phone_or_mobile_cont].to_s.strip.presence

    if main_keyword && (main_keyword =~ /\A\d+\z/)
      @ransack_params[:id_eq] = main_keyword.to_i
      @ransack_params[:m] = 'or'
    end

    @search_query = current_business.contacts.not_archived.ransack(@ransack_params)

    @contacts = @search_query
      .result
      .order(business_name: :asc)
      .page(params[:page])

  end

  def show
    authorize! :read, Contact
  end

  def new
    authorize! :create, Contact

    @contact = current_business.contacts.new
    if params[:referral_id].present? && current_business.referrals.exists?(id: params[:referral_id])
      referral = current_business.referrals.find(params[:referral_id])
      @contact.business_name = referral.referrer_business_name
      @contact.email = referral.referrer_email
      @contact.phone = referral.referrer_phone
      @contact.first_name = referral.referrer_name.split(" ", 2)[0]
      @contact.last_name = referral.referrer_name.split(" ", 2)[1]
    end
  end

  def edit
    authorize! :edit, Contact
  end

  def create
    authorize! :create, Contact
    @contact = current_business.contacts.new(contact_params)

    respond_to do |f|
      if @contact.save
        if params[:referral_id].present? && current_business.referrals.exists?(id: params[:referral_id])
          referral = current_business.referrals.find(params[:referral_id])
          referral.update_column :linked_contact_id, @contact.id
        end
        ::Webhook::Worker.perform_later(@contact.id, WebhookSubscription::CONTACT_CREATED)
        if params[:invoice_to_patient_id]
          patient = current_business.patients.find params[:invoice_to_patient_id]
          patient.update invoice_to_contact_ids: patient.invoice_to_contacts.map(&:id)
                                                        .push(@contact.id)
        end

        f.js
        f.html do
          redirect_to contact_url(@contact), notice: 'Contact was successfully created.'
        end
        f.json { render json: { contact: @contact }, status: :created }
      else
        f.js
        f.html { render :new }
        f.json do
          render(
            json: { errors: @contact.errors.full_messages },
            status: :unprocessable_entity
          )
        end
      end
    end
  end

  def update
    authorize! :update, Contact

    if @contact.update(contact_params)
      redirect_to contact_url(@contact),
                  notice: 'Contact was successfully updated.'
    else
      render :edit
    end
  end

  def possible_duplicates
    @contacts = FindDuplicateContactsService.new.call(
      current_business,
      @contact
    )

    respond_to do |f|
      f.js
    end
  end

  def merge
    authorize! :merge, Contact

    MergeContactsService.new.call(
      @contact,
      current_business.contacts.where(id: params[:contact_ids].to_a).to_a,
      current_user
    )

    redirect_to contact_url(@contact),
                notice: 'The contacts has been successfully merged.'
  end

  def archive
    authorize! :archive, Contact

    @contact.update archived_at: Time.current
    redirect_to contacts_url, notice: 'The contact was successfully archived.'
  end

  def destroy
    authorize! :destroy, Contact

    @contact.destroy_by_author(current_user)
    redirect_to contacts_url, notice: 'The contact was successfully deleted.'
  end

  def invoices
    authorize! :read, Contact
    @invoices = @contact.invoices.includes(:appointment, :patient)
                        .order(issue_date: :DESC)
                        .page(params[:page])
  end

  def patients
    authorize! :read, Contact

    respond_to do |f|
      f.html do
        @search_query = @contact.patients

        if !params[:include_archived].present?
          @search_query = @search_query.where(archived_at: nil)
        end

        @search_query = @search_query.ransack(params[:q].try(:to_unsafe_h))

        @patients = @search_query.result
                    .order("patients.last_name ASC")
                    .group(:id)
                    .page(params[:page])
      end

      f.csv do |f|
        patient_export = Export::Patients.make(current_business, {contact_ids: [@contact.id]})
        csv_file_name = "#{@contact.business_name.parameterize}_clients.csv"
        send_data patient_export.as_csv, filename: csv_file_name
      end
    end
  end

  def update_important_notification
    authorize! :update, Contact

    content = params[:important_notification].strip
    @contact.update_attribute :important_notification, content.presence
    render json: { success: true }
  end

  private

  def set_contact
    @contact = current_business.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(
      :business_name,
      :title,
      :first_name,
      :last_name,
      :company_name,
      :phone,
      :mobile,
      :fax,
      :email,
      :address1,
      :address2,
      :address,
      :city,
      :state,
      :postcode,
      :country,
      :notes
    )
  end
end
