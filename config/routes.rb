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

  resource :mfa, only: [], controller: 'mfa' do
    get :setup
    post :enable
    delete :disable
  end

  resource :mfa_session, only: [:new, :create] do
    post :verify_backup_code
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

  # ========================================
  # DIRECT MESSAGING ROUTES
  # ========================================

  # Friendships routes
  resources :friendships, only: [:index, :create, :destroy] do
    member do
      patch :accept
      delete :reject
    end
  end
  # Messages routes
  resources :messages, only: [:index, :create] do
    collection do
      get :conversations
      delete :clear, to: 'messages#clear', as: 'clear'  # Clear chat action
    end
  end
  # ActionCable mount for real-time messaging
  mount ActionCable.server => '/cable'

  #collaborations
  resources :events do
    resources :ai_gift_suggestions, only: [:index, :create] do
      member do
        post :toggle_wishlist
      end
    end

    resources :collaborators, only: [:create, :update, :destroy]

    member do
      post :add_recipient
      delete :remove_recipient
    end
  end

  resources :collaboration_requests, only: [:index] do
    member do
      post   :accept
      delete :reject
    end
  end


  # ak

  # Cart
  resource :cart, only: [:show]
  resources :cart_items, only: [:create, :destroy] do
    collection do
      post :bulk_create_from_wishlist
      delete :clear
    end
  end

  # Orders
  resources :orders, only: [:index, :show, :create] do
    member do
      patch :cancel
      patch :deliver
    end
  end


  # ak
  resources :wishlists, only: [:index] do
    member do
      post :move_to_cart
    end
  end




  get "up" => "rails/health#show", as: :rails_health_check
end