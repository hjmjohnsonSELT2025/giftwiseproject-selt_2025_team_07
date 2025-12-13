# config/initializers/session_store.rb
# Secure session configuration

Rails.application.config.session_store :cookie_store,
                                       key: '_gift_manager_session',
                                       expire_after: 2.hours,
                                       secure: Rails.env.production?,
                                       httponly: true,
                                       same_site: :lax,
                                       domain: Rails.env.production? ? ENV['APP_DOMAIN'] : nil

Rails.application.config.action_dispatch.cookies_serializer = :json
Rails.application.config.session_timeout = 2.hours