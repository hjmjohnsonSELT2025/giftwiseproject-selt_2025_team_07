Rails.application.routes.draw do
  get 'profiles/edit'
  get 'profiles/update'
  root "home#index"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  delete "logout", to: "sessions#destroy"

  get "dashboard", to: "dashboard#index"
  resource :profile, only: [:edit, :update]

   resources :events
   resources :recipients

  get "up" => "rails/health#show", as: :rails_health_check
end