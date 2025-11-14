Rails.application.routes.draw do
  root "home#index"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  delete "logout", to: "sessions#destroy"

  get "dashboard", to: "dashboard#index"

  resources :events do
    member do
      # Add a recipient to the event
      post :add_recipient
      # Remove a recipient from the event
      delete :remove_recipient
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end