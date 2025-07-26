Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :businesses, only: [:show] do
      collection do
        get :info
      end
    end
    resources :contacts, only: [:show] do
      collection do
        get :search
      end
    end

    resources :products, only: [:index, :show]
    resources :billable_items, only: [:index, :show]
    resources :patient_cases, only: [:index, :show]

    resources :account_statements, only: [:show] do
      collection do
        get :search
      end
    end

    resources :invoices, only: [:show] do
      collection do
        get :search
        get :outstanding_search
      end
    end

    resources :appointment_types, only: [:show]

    resources :patients, only: [:create, :show] do
      member do
        get :patient_cases
        get :invoice_to_contacts
        get :appointments
        get :recent_invoices
        get :payment_methods
      end

      collection do
        get :search
      end
    end

    resources :practitioners, only: [:show] do
      collection do
        get :search
      end
    end

    resources :appointments, only: [:show, :create, :update, :destroy] do
      collection do
        post :creates
      end
      member do
        put :update_status
        put :cancel
        post :send_review_request
        get :attendance_proofs
        post :attendance_proofs, action: :create_attendance_proof
        delete 'attendance_proofs/:attendance_proof_id', action: :destroy_attendance_proof
        put :mark_confirmed
        put :mark_unconfirmed
        post :send_arrival_time
      end
    end

    resources :availabilities do
      member do
        put :update_appointments_order
        post :send_arrival_times
        put :optimize_route
        put :calculate_route
        put :change_practitioner
        put :lock_order
        put :unlock_order
        put :update_time
        post :send_bulk_sms
      end

      collection do
        get :search_by_date
        # get :practitioner_home_visit
        # get :practitioner_facility
        post :single_home_visit
        post :non_billable
        post :group_appointment
      end
    end

    resources :wait_lists do
      member do
        put :mark_scheduled
      end
    end

    resources :referrals, only: [:show]
    resources :tasks, only: [:show] do
      collection do
        get :completed
      end
    end

    get 'calendar/appearance_settings' => 'appearance_settings#show'
    put 'calendar/appearance_settings' => 'appearance_settings#update'

    get 'search_appointment' => 'search_appointment#index'
    post 'communications/build_content' => 'communications#build_content'
    post 'communications/send_patient_message' => 'communications#send_patient_message'

    get 'communications/sms_conversations' => 'communications#sms_conversations'
    get 'communications/sms_conversations/unread_count' => 'communications#unread_conversations_count'
    get 'communications/patient_sms_conversations/:patient_id' => 'communications#patient_sms_conversations'
    post 'communications/patient_sms_conversations/:patient_id/send_message' => 'communications#send_message'
    post 'communications/patient_sms_conversations/:patient_id/mark_as_read' => 'communications#mark_as_read_conversation'
  end
end
