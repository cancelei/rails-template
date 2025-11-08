Rails.application.routes.draw do
  resources :guide_profiles, only: %i[show edit update]
  authenticate :user do
    # routes created within this block can only be accessed by a user who has
    # logged in. For example:
    # resources :things
    resource :history, only: [:show], controller: "history", as: :history

    # Guide dashboard for managing own profile and tours
    resource :guide_dashboard, only: %i[show edit update], controller: "guides/dashboard"

    # Nested routes for guide profile updates
    namespace :guides do
      resource :profile, only: [:update]
      resources :tours, only: [:index]
      resources :bookings, only: %i[index edit update] do
        member do
          patch :cancel
        end
      end
    end
  end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }, skip: [:registrations]

  # Guide landing page (public)
  get "become-a-guide", to: "guides/landing#index", as: :become_a_guide

  # Custom registration routes
  devise_scope :user do
    # Tourist registration
    get "signup", to: "tourists/registrations#new", as: :new_tourist_registration
    post "signup", to: "tourists/registrations#create", as: :tourist_registration

    # Guide registration
    get "guides/signup", to: "guides/registrations#new", as: :new_guide_registration
    post "guides/signup", to: "guides/registrations#create", as: :guide_registration

    # Standard Devise routes
    get "users/edit", to: "users/registrations#edit", as: :edit_user_registration
    patch "users", to: "users/registrations#update", as: :user_registration
    delete "users", to: "users/registrations#destroy"

    # Magic link for passwordless auth
    get "users/magic_link/:token", to: "users/sessions#magic_link", as: :magic_link
  end

  root "home#index"
  mount OkComputer::Engine, at: "/healthchecks"

  resources :tours, only: %i[index show new create edit update] do
    resources :bookings, only: [:create]
  end

  resources :bookings, only: [] do
    member do
      get :manage
      post :cancel
      post :review
    end
  end

  namespace :admin do
    get :metrics
    resources :users, :tours, :bookings, :reviews, :guide_profiles, :weather_snapshots, :email_logs

    resources :tours, only: [] do
      resources :tour_add_ons, path: "add-ons" do
        collection do
          post :reorder
        end
      end
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

  resources :guide_profiles do
    resources :comments, only: [:create]
  end

  resources :comments do
    member do
      post :toggle_like
    end
  end
end
