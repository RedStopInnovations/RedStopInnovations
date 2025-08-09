Rails.application.routes.draw do
  get 'health-check', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }

  # ============================================================================
  # Devise/Auth routes
  # ============================================================================
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    invitations: 'users/invitations',
  }

  devise_scope :user do
    post 'users/registrations/email_verification_code', to: 'users/registrations#email_verification_code', as: :user_email_verification_code
  end

  root 'frontend/pages#home'

  # ============================================================================
  # App dashboard routes
  # ============================================================================
  scope :app do
    get 'dashboard', to: 'dashboard#index'
    get 'dashboard/overview_report_content', to: 'dashboard#overview_report_content'
    get 'settings', to: 'settings#index'
    # get 'zapier', to: 'dashboard#zapier', as: :dashboard_zapier
    get 'calendar', to: 'calendar#index'
    get 'calendar/search-appointment', to: 'calendar#search_appointment'
    get 'calendar/map', to: 'calendar#map'

    get 'reports' => 'reports#index', as: :reports
    get 'reports/business_revenue', to: 'reports#business_revenue'
    get 'reports/deleted_items', to: 'reports#deleted_items'

    # resources :tutorials
    resources :api_keys, only: [:create, :destroy]
    resources :tasks do
      collection do
        get :new_completed
        post :create_completed
        get :mine
        post :bulk_mark_invoice_not_required
      end

      member do
        put :complete
        get :modal_update_completion
        get :modal_edit_completion
        post :mark_invoice_required
        post :mark_invoice_not_required
      end
    end

    namespace :reports do
      resources :invoices_pdf_exports, only: [:index, :show, :create] do
        member do
          get :download
        end
      end
      scope controller: :patient_cases, path: 'patient-cases', as: :patient_cases do
        get :all
        get :invoice_without_case, path: 'invoice-without-case'
        get :invoice_total_per_case, path: 'invoice-total-per-case'
      end

      scope :payrolls, controller: :payrolls do
        get :summary
      end

      scope :employees, controller: :employees, as: :employees do
        get :roster
        post :roster_deliver
        post :send_all_rosters
      end

      resources :attendance_proof_exports, only: [:index, :show, :create] do
        member do
          get :download
        end
      end

      scope :contacts, controller: :contacts do
        get :referral_source, path: 'referral-source'
        get :total_patients, as: :contacts_total_patients
        get :total_invoice, as: :contacts_total_invoice
        get :contact_duplicates, action: :duplicates
        get :account_statements, as: :contact_account_statements
      end

      scope :appointments, controller: :appointments do
        get :appointments_schedule
        get :uninvoiced_appointments
        get :cancelled_appointments
        get :appointments_incomplete
        get :uninvoiced_tasks
      end

      scope :patients, controller: :patients do
        get :patients_without_upcoming_appointments
        get :patients_account_credit
        get :patient_invoices
        get :patient_duplicates
        get :new_patient
        get :account_statements, as: :patient_account_statements
      end

      scope :transactions, controller: :transactions do
        get :outstanding_invoices
        get :invoices_raised
        get :payment_summary
        get :daily_payments
        get :voided_invoices
        get :product_sales
      end

      scope :practitioners, controller: :practitioners do
        get :practitioner_performance
        get :practitioner_performance_legacy # @TODO: remove later
        get :practitioner_reviews
        get :practitioner_documents
        get :practitioner_travel
        get :single_practitioner_travel
        get :practitioner_availability
        post :send_practitioner_performance
        post :send_practitioner_performance_legacy # @TODO: remove later
      end

      scope :treatment_notes, controller: :treatment_notes do
        get :draft_treatment_notes # @TODO: remove later
        get :list_all_treatment_notes, action: :list_all
        get :appointments_without_treatment_note
        get :triggers_by_word
        get :triggers_by_category
      end

      resources :dva_claims, only: [:index, :show]
      resources :bulk_bill_claims, only: [:index, :show]
      get 'eclaims/medicare', to: 'eclaims#medicare', as: :eclaims_medicare
      get 'eclaims/dva', to: 'eclaims#dva', as: :eclaims_dva
      get 'eclaims/ndis', to: 'eclaims#ndis', as: :eclaims_ndis
      get 'eclaims/proda', to: 'eclaims#proda', as: :eclaims_proda

      get :business_leads, to: 'business_leads#index'
    end

    resources :case_types, path: 'case-types'
    # resources :patient_cases, path: 'patient-cases' do
    #   member do
    #     put :discharge
    #     put :open
    #     put :archive
    #     put :unarchive
    #   end
    # end
    resources :outcome_measure_types, except: [:destroy], path: 'outcome-measure-types'
    resources :contacts do
      member do
        get :invoices
        get :patients
        get :possible_duplicates
        post :merge
        put :update_important_notification
        put :archive
      end

      resources :account_statements,
                controller: :contact_account_statements,
                only: [:index, :show, :destroy] do
        collection do
          get :published
          post :publish
        end

        member do
          post :send_to_contact
          post :regenerate
        end
      end

      resources :contact_communications,
                path: 'communications',
                as: :communications,
                only: [:index, :show]
    end
    resources :invoices do
      collection do
        get :modal_bulk_create_from_uninvoiced_appointments
        post :bulk_create_from_uninvoiced_appointments
        post :bulk_send_outstanding_reminder
      end

      member do
        post :send_medipass_request
        post :resend_medipass_request
        get :payments
        get :preview_medipass_payment_request
        post :send_quote
        get :preview_dva_payment
        post :send_dva_payment
        get :preview_bulk_bill_payment
        post :send_bulk_bill_payment
        put :mark_as_sent
        put :enable_outstanding_reminder
        put :disable_outstanding_reminder
        get :activity_log
        get :modal_send_email
        post :send_email
      end
    end

    resources :patients do
      member do
        get :invoices
        # get :treatment_notes
        get :appointments
        get :payments
        post :merge
        get :possible_duplicates
        put :archive
        put :unarchive
        get :invoice_info
        get :outstanding_invoices
        get :edit_access
        put :update_access
        get :access_disallowed
        put :update_card
        delete :delete_card
        get :open_in_physitrack
        put :update_important_notification
        get :contacts
        get :credit_card_info
        get :edit_associate_contacts
        put :update_associate_contacts
        get :edit_payment_methods
        put :update_payment_methods
      end
      resources :attachments, controller: :patient_attachments do
        member do
          post :send_to_contacts
          post :send_to_patient
          get :modal_email_others
        end
      end

      resources :account_statements,
                controller: :patient_account_statements,
                only: [:index, :show, :destroy] do
        collection do
          get :published
          post :publish
        end

        member do
          post :send_to_patient
          post :send_to_contacts
          get :pre_send_to_contacts
          post :regenerate
        end
      end

      resources :patient_communications,
                path: 'communications',
                as: :communications,
                only: [:index, :show]

      resources :patient_letters, path: 'letters', as: :letters do
        member do
          post :send_patient
          post :send_others
        end
      end

      resources :outcome_measures do
        member do
          get :send_to_patient
          get 'tests/:test_id/edit', action: :edit_test, as: :edit_test
          post 'tests', action: :create_test, as: :create_test
          put 'tests/:test_id', action: :update_test, as: :update_test
          delete 'tests/:test_id', action: :delete_test, as: :delete_test
        end
      end

      resources :treatments do
        member do
          get :export_pdf
          get :modal_send_email
          post :send_email
        end

        collection do
          get :last_treatment_note
        end
      end

      resources :cases, controller: :patient_cases do
        member do
          put :discharge
          put :open
          put :archive
          put :unarchive
        end
      end
    end

    resources :imports do
      collection do
        post :match_fields
        post :import_fields
      end
    end

    resources :payments do
      collection do
        get :bulk
        post :bulk_create
        get :pre_stripe_payment
        post :stripe_payment
      end
    end

    resources :appointments, only: [:index, :show, :destroy] do
      collection do
        post :bulk_mark_invoice_not_required
        post :bulk_send_review_request
        get :appointments_count_daily
        get :list_by_date
      end

      member do
        get :modal_review_request
        get :modal_send_follow_up_reminder
        post :send_review_request
        post :mark_confirmed
        post :mark_unconfirmed

        post :mark_invoice_required
        post :mark_invoice_not_required
      end


    end
    resources :appointment_types
    resources :billable_items
    resources :treatment_templates
    resource :business_profile, controller: :business_profile, only: [:edit, :update]
    resources :products
    resources :communications, except: [:edit, :update]
    resources :taxes
    resources :letter_templates do
      member do
        get :preview
      end
    end
    resources :wait_lists, only: [:destroy] do
      collection do
        get :print
      end
      member do
        put :mark_scheduled
      end
    end
    resources :communication_templates, only: [:index, :edit, :update] do
      member do
        get :preview
      end
    end

    resources :business_invoices, only: [:show] do
      member do
        get :billed_items
      end
    end

    resources :invoice_batches do
      collection do
        get :uninvoiced_appointments_search
      end

      member do
        post :send_email
      end
    end

    # Begin settings scope
    scope :settings, module: :settings, as: :settings do
      resources :practitioner_groups, path: 'practitioner-groups'
      resources :payment_types, only: [:index, :edit, :update]
      resources :notification_types, only: [:index, :edit, :update]
      resources :availability_subtypes

      get 'online_bookings', to: 'online_bookings#index'
      get 'online_bookings/generate_url', to: 'online_bookings#generate_url'

      get 'team_page', to: 'iframes#team_page', as: :team_page_iframe
      get 'team_page/generate_url', to: 'iframes#generate_team_page_url'
      get 'referral_iframe', to: 'iframes#referral', as: :referral_iframe

      get 'marketing_tracking', to: 'marketing_tracking#index'
      put 'marketing_tracking/update_google_tag_manager', to: 'marketing_tracking#update_google_tag_manager', as: :update_google_tag_manager

      resources :users, except: [:destroy] do
        member do
          post :change_signature
          post :resend_invitation_email
          put :update_avatar
          get :allocated_items
          post :update_allocated_appointment_types
          post :update_allocated_billable_items
          post :update_allocated_treatment_templates
          get :login_activity
          get :modal_practitioner_documents, action: :modal_practitioner_documents
          post :update_practitioner_document, action: :update_practitioner_document
          post :update_password, action: :update_password
          post :send_reset_password_email, action: :send_reset_password_email
          put :remove_2fa, action: :remove_2fa
          delete :delete_practitioner_document, action: :delete_practitioner_document

          get :timeable_settings, action: :timeable_settings
          post :business_hours, action: :update_business_hours
        end
      end

      resources :invoice_diagnoses
      resources :invoice_services

      put 'business_settings' => 'business#update'
      get 'storage_documents' => 'business#storage_documents'
      get 'subscriptions', to: 'subscriptions#index'
      post 'subscriptions/add_card_details', to: 'subscriptions#add_card_details'
      get 'subscriptions/invoices', to: 'subscriptions#invoices'
      get 'subscriptions/payments', to: 'subscriptions#payments'
      resources :mailchimps, except: [:destroy]
      get 'stripe_connect_callback', to: 'stripe_integration#authorize_callback'

      resources :treatment_shortcuts
      resources :tags

      scope :medipass_integration,
            controller: :medipass_integration,
            as: :medipass_integration do

        get '/', action: :show
        get :setup
        post :update_account
      end

      scope :stripe_integration,
            controller: :stripe_integration,
            as: :stripe_integration do

        get '/', action: :show
        get :authorize
        put :deauthorize
      end

      scope :invoice, controller: :invoice_setting, as: :invoice do
        get '/', action: :show
        put '/', action: :update
      end

      scope :patient_access, controller: :patient_access, as: :patient_access do
        get '/', action: :show
        put :save_settings
      end

      scope :claiming_integration, controller: :claiming_integration, as: :claiming_integration do
        get '/', action: :show
        get :registered_providers
        get :setup
        post :register
        get :register_providers
        post :register_providers, action: :post_register_providers
      end

      scope :bookings_questions, controller: :bookings_questions, as: :bookings_questions do
        get '/', action: :index
        post '/', action: :update
      end

      resources :trigger_categories

      scope :physitrack_integration, controller: :physitrack_integration, as: :physitrack_integration do
        get '/', action: :show
        put '/', action: :update
      end
    end
    # End settings scope
  end

  namespace :app do
    put 'my_preferences/update', to: 'my_preferences#update'
    resources :referrals do
      collection do
        post :bulk_archive
      end
      member do
        put :approve
        put :update_progress
        put :archive
        put :unarchive
        get :modal_show
        get :modal_find_practitioners
        put :update_internal_note
        put :assign_practitioner
        put :reject
        get :modal_reject_confirmation
        get :find_first_appointment
        delete 'attachments/:attachment_id', action: :delete_attachment, as: :delete_attachment
      end
    end

    post 'internal_communications/send_email', to: 'internal_communications#send_email', as: :internal_communication_send_email

    resources :conversations

    resources :patients do
      resources :id_numbers, controller: :patient_id_numbers, path: 'id-numbers' do
      end
    end

    scope :mfa_authentication, controller: :mfa_authentication, as: :mfa_authentication do
      get '/verify', action: :verify
      post '/verify_code', action: :verify_code
    end

    scope :patient_bulk_archive, controller: :patient_bulk_archive, as: :patient_bulk_archive do
      get '/', action: :index
      get '/search', action: :search
      get '/requests', action: :requests
      post '/create_request', action: :create_request
    end

    namespace :account_settings do
      scope :google_calendar_sync, controller: :google_calendar_sync, as: :google_calendar_sync do
        get '/', action: :index
        get '/authorize', action: :authorize
        get '/authorize_callback', action: :authorize_callback
        put '/deauthorize', action: :deauthorize
      end

      scope :profile, controller: :profile, as: :profile do
        get '/', action: :index
        put '/', action: :update
        post '/change_signature', action: :change_signature
        put '/update_avatar', action: :update_avatar
        put '/update_password', action: :update_password
        get '/pre_change_password', action: :pre_change_password
        get '/modal_practitioner_documents', action: :modal_practitioner_documents
        post '/update_practitioner_document', action: :update_practitioner_document
        delete '/delete_practitioner_document', action: :delete_practitioner_document
      end

      scope :timeable_settings, controller: :timeable_settings, as: :timeable_settings do
        get '/', action: :index
        post '/business_hours', action: :update_business_hours
      end

      scope :api_keys, controller: :api_keys, as: :api_keys do
        get '/', action: :index
        post '/', action: :create, as: :create
        delete '/:id', action: :destroy, as: :destroy
      end

      scope :security, controller: :security, as: :security do
        get '/', action: :index
      end

      scope :tfa_authentication, controller: :tfa_authentication, as: :tfa_authentication do
        get '/setup', action: :setup
        post '/enable', action: :enable
        get '/modal_disable', action: :modal_disable
        post '/disable', action: :disable
      end
    end

    namespace :data_export do
      resources :account_statements_exports, only: [:index, :show, :create] do
        member do
          get :download
        end
      end

      resources :treatment_notes_exports, only: [:index, :show, :create] do
        member do
          get :download
        end
      end

      resources :patient_attachments_exports, only: [:index, :show, :create] do
        member do
          get :download, as: :download
        end
      end

      resources :patient_letters_exports, only: [:index, :show, :create] do
        member do
          get :download
        end
      end

      scope :exports, controller: :exports do
        get :patients
        get :contacts
        get :appointment_types
        get :billable_items
        get :practitioner_documents
        get :users
        get :communications
        get :products
        get :practitioners_timeable_settings
        get :waiting_list
        get :patient_letters
      end
    end
  end

  namespace :iframe, path: '' do
    get 'embed/team/:business_id/:business_slug/:practitioner_id/:practitioner_slug', to: 'team_page#single', as: :team_practitioner_profile_page
    get 'embed/team/:business_id/:business_slug', to: 'team_page#team', as: :team_page

    get 'embed/team/:id-:slug', to: 'practitioners#team', as: :team
    get 'embed/practitioner/:id-:slug', to: 'practitioners#single', as: :practitioner
    get '/referral/embed(/:template)', to: 'referrals#new', as: :referral
    post '/referral/embed', to: 'referrals#create', as: :create_referral
  end

  # ============================================================================
  # Sitemaps
  # ============================================================================
  get 'sitemap' => 'sitemaps#show'

  # ============================================================================
  # Web hooks
  # ============================================================================
  post '_hooks/medipass', to: 'hooks#medipass', as: :medipass_hook
  post '_hooks/sendgrid', to: 'hooks#sendgrid', as: :sendgrid_hook
  post '_hooks/twilio_sms_delivery/:tracking_id', to: 'hooks#twilio', as: :twilio_sms_delivery_hook

  get 'stmtinv/:public_token/:invoice_id/',
      to: 'public_invoices#show',
      as: :account_statement_invoice_public

  # Online invoices payment with Stripe
  # Notes: :token can be invoice ID(old) or public_token
  get 'invoice-payment/:token' => 'invoice_payment#show',
      as: :public_invoice_payment
  post 'invoice-payment/:token' => 'invoice_payment#process_payment'

  get 'reviews/:appointment_token'  => 'reviews#new', as: :add_review
  post 'reviews/:appointment_token'  => 'reviews#create', as: :create_review

  post '_trk' => 'events_tracking#save'
end
