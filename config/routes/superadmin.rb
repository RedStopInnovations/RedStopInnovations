require 'sidekiq/web'
require 'sidekiq/cron/web'

super_admin_prefix = '___sadmin'

Rails.application.routes.draw do
  # ============================================================================
  # Administrator routes
  # ============================================================================

  authenticate :admin_user do
    mount Sidekiq::Web => "/#{super_admin_prefix}/sidekiq"
  end

  devise_for :admin_users, path: super_admin_prefix, controllers: {
    sessions: 'admin/sessions'
    # passwords: 'admin/passwords'
  }

  devise_scope :admin_user do
    scope path: super_admin_prefix do
      get 'sessions/verify_2fa', to: 'admin/sessions#verify_2fa',
        as: :admin_sessions_verify_2fa
      post 'sessions/post_verify_2fa', to: 'admin/sessions#post_verify_2fa',
        as: :admin_sessions_post_verify_2fa
      post 'sessions/resend_verify_2fa_code', to: 'admin/sessions#resend_verify_2fa_code',
        as: :admin_sessions_resend_verify_2fa_code
    end
  end

  namespace :admin, path: super_admin_prefix do
    root to: 'dashboard#index'
    get 'tools', to: 'tools#index', as: :tools
    get 'dashboard', to: 'dashboard#index', as: :dashboard
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        post :resend_invitation_email
        get :login_as
        post :delete_avatar
        post :remove_tfa
        post :deactivate
        post :activate
      end
    end

    get 'profile', to: 'profile#show', as: :profile
    put 'profile', to: 'profile#update', as: :update_profile
    resources :practitioners, only: [:index, :show, :edit, :update] do
     collection do
        post :bulk_approve_profile
        post :bulk_reject_profile
      end
      member do
        put :approval
        post :delete_avatar
      end
    end
    resources :referrals do
      member do
        put :assign_business, path: 'assign-business'
        post :send_nearby_practitioners, path: 'send-nearby-practitioners'
      end
    end
    resources :courses
    resources :tags
    resources :businesses, only: [:index, :show, :edit, :update] do
      collection do
        post :bulk_approve
        post :bulk_suspend
      end
      member do
        put :approve
        put :suspend
      end
    end
    resources :seopages
    resources :receptionists
    resources :posts, except: [:new, :create] do
      member do
        put :approval
      end
    end
    resources :patients, only: [:index, :show, :edit, :update] do
      member do
        get :invoices
        get :payments
        get :appointments
      end
    end

    resources :invoices, only: [:index, :show]
    resources :payments, only: [:index, :show]
    resources :subscription_discounts
    resources :subscriptions, only: [:index, :show] do
      member do
        get :invoices
        get :payments
        put :update_settings
      end
    end
    resources :subscription_payments
    resources :business_invoices do
      member do
        post :charge
        get :billed_items
        delete :delete_billed_item
        post :deliver
        put :reset_items
      end
    end
    resources :reviews do
      member do
        put :approval
      end
    end

    get 'settings', to: 'dashboard#settings'
    get 'reports' => 'reports#index', as: :reports

    namespace :reports do
      scope :appointments, controller: :appointments do
        get :appointments_summary
      end
      scope :subscriptions, controller: :subscriptions do
        get :revenue_summary
        get :lifetime_value_summary
      end

      scope :business, controller: :business do
        get :business_leads
        get 'business_leads_details/:business_id',
            action: :business_leads_details,
            as: :business_leads_details
      end

      scope :analytics, controller: :analytics, as: :analytics do
        get '/events' => :events
      end
    end
  end
end
