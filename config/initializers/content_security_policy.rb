# config/initializers/content_security_policy.rb
# XSS Protection via Content Security Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none

  # FOR CHATBOT: Allow inline scripts and eval in development
  # Allow inline scripts and eval for chatbot
  if Rails.env.development?
    policy.script_src  :self, :https, :unsafe_eval, :unsafe_inline
  else
    policy.script_src  :self, :https, :unsafe_eval, :unsafe_inline
  end

  policy.style_src   :self, :https, :unsafe_inline

  policy.connect_src :self, :https,
                     "ws://localhost:3000",
                     "wss://localhost:3000",
                     "ws://127.0.0.1:3000",
                     "wss://#{ENV['APP_DOMAIN']}"

  policy.base_uri    :self
  policy.form_action :self
  policy.frame_ancestors :none
end

Rails.application.config.content_security_policy_nonce_generator = lambda { |request|
  request.session.id.to_s
}

Rails.application.config.content_security_policy_nonce_directives = %w[script-src style-src]