Rails.application.routes.draw do
  scope :app do
    namespace :virtual_receptionist do
      get '/' => 'dashboard#index', as: :dashboard

      get 'patients/search' => 'patients#search', as: :patients_search
      get 'patients/:id/future_appointments_list' => 'patients#future_appointments_list', as: :future_appointments_list
      post 'patients/:id/appointments/:appointment_id/cancel' => 'patients#cancel_appointment', as: :cancel_appointment
    end
  end
end