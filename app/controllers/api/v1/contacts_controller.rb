module Api
  module V1
    class ContactsController < V1::BaseController
      before_action :find_contact, only: [:show, :update]

      def index
        contacts = current_business.
          contacts.
          order(id: :asc).
          ransack(jsonapi_filter_params).
          result.
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: contacts,
               meta: pagination_meta(contacts)
      end

      def show
        render jsonapi: @contact
      end

      def create
        contact = current_business.contacts.new contact_params

        if contact.save
          ::Webhook::Worker.perform_now(contact.id, WebhookSubscription::CONTACT_CREATED)
          render jsonapi: contact, status: 201
        else
          render jsonapi_errors: contact.errors, status: 422
        end
      end

      def update
        @contact.assign_attributes contact_params

        if @contact.save
          render jsonapi: @contact
        else
          render jsonapi_errors: @contact.errors, status: 422
        end
      end

      def poll
        contact = current_business.contacts
                                  .order(id: :desc)
                                  .first
        result = []
        result << Webhook::Contact::Serializer.new(contact).as_json if contact
        render json: result
      end

      private

      def find_contact
        @contact = current_business.contacts.find(params[:id])
      end

      def contact_params
        params.require(:data).permit(attributes: [
          :business_name,
          :title,
          :first_name,
          :last_name,
          :phone,
          :mobile,
          :fax,
          :email,
          :address1,
          :address2,
          :city,
          :state,
          :postcode,
          :country,
          :notes
        ]).tap do |whitelisted|
          whitelisted[:metadata] = params[:data][:attributes][:metadata]
          whitelisted.permit!
        end
      end

      def jsonapi_whitelist_filter_params
        [
          :id_eq,

          :business_name_eq,
          :business_name_cont,

          :first_name_eq,
          :first_name_cont,

          :last_name_eq,
          :last_name_cont,

          :email_cont,
          :phone_cont,
          :mobile_cont,

          :city_eq,
          :state_eq,
          :postcode_eq,

          :created_at_lt,
          :created_at_lteq,
          :created_at_gt,
          :created_at_gteq,

          :updated_at_lt,
          :updated_at_lteq,
          :updated_at_gt,
          :updated_at_gteq
        ]
      end
    end
  end
end
