Rails.application.routes.draw do
  devise_for :admins

  get "/lp/:slug", to: "landing_pages#show", as: :landing_page

  namespace :admin do
    root to: "dashboard#index"
    resources :clients, only: %i[index new create edit update destroy] do
      resource :landing_page, only: %i[new create edit update destroy]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
