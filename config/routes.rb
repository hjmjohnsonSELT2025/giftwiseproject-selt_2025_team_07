Rails.application.routes.draw do
  get 'dashboard/index'
  get "home/index"
  get "up" => "rails/health#show", as: :rails_health_check

  # Public landing page
  root "home#index"

  # Logged-in home
  get "dashboard", to: "dashboard#index"
end
