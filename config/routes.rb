Rails.application.routes.draw do
  get 'profiles/edit'
  get 'profiles/update'
  root "home#index"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "dashboard", to: "dashboard#index"
  resource :profile, only: [:edit, :update]

  get "up" => "rails/health#show", as: :rails_health_check
end