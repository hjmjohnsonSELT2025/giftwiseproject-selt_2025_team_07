Rails.application.routes.draw do
  root "home#index"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "dashboard", to: "dashboard#index"

   resources :events


  get "up" => "rails/health#show", as: :rails_health_check
end