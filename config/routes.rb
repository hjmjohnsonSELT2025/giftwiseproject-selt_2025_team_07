Rails.application.routes.draw do
  root "home#index"

  get  "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get    "logout", to: "sessions#destroy"

  get 'auth/:provider/callback', to: 'sessions#omniauth'
  post 'auth/:provider/callback', to: 'sessions#omniauth'
  get 'auth/failure', to: 'sessions#auth_failure'

  get 'forgot_password', to: 'password_resets#new'
  post 'forgot_password', to: 'password_resets#create'
  get 'reset_password/:token', to: 'password_resets#edit', as: :reset_password
  patch 'reset_password/:token', to: 'password_resets#update'

  get "dashboard", to: "dashboard#index"

  get "/ai_gift_library", to: "ai_gift_suggestions#library", as: :ai_gift_library
  get "chatbot", to: "chatbots#show"

  # Chatbot API
  post "chatbot/message", to: "chatbots#message"


  resource :profile, only: [:edit, :update]

  resource :password, only: [:edit, :update]

  get "/passwords/edit",   to: "passwords#edit"
  get "/passwords/update", to: "passwords#edit"

  resources :recipients do
    resources :gift_ideas, only: [:new, :create, :destroy]
    resources :gift_given_backlogs, only: [:new, :create, :destroy]
  end

  resources :events do
    resources :ai_gift_suggestions, only: [:index, :create] do
      member do
        post :toggle_wishlist
      end
    end

    member do
      post :add_recipient
      delete :remove_recipient
    end
  end

  resources :wishlists, only: [:index]

  get "up" => "rails/health#show", as: :rails_health_check
end