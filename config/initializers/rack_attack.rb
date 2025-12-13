# config/initializers/rack_attack.rb
# Rate limiting configuration

class Rack::Attack

  safelist('allow-chatbot') do |req|
    # Allow all chatbot-related paths
    req.path.start_with?('/chatbots') ||
      req.path.start_with?('/chat') ||
      req.path == '/chatbot'  # Adjust based on your route
  end

  # Throttle login attempts by email address
  # Allow 5 login attempts per 60 seconds per email
  throttle('login/email', limit: 5, period: 60.seconds) do |req|
    if req.path == '/login' && req.post?
      req.params['email'].to_s.downcase.presence
    end
  end

  # Throttle login attempts by IP address
  # Allow 10 login attempts per 60 seconds per IP
  throttle('login/ip', limit: 10, period: 60.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  # Throttle password reset requests
  # Allow 3 password reset requests per 5 minutes per IP
  throttle('password_reset/ip', limit: 3, period: 5.minutes) do |req|
    if req.path == '/password_resets' && req.post?
      req.ip
    end
  end

  # Throttle signup attempts
  # Allow 5 signups per hour per IP
  throttle('signup/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/signup' && req.post?
      req.ip
    end
  end

  # Throttle friend requests
  # Allow 20 friend requests per hour per user
  throttle('friendships/user', limit: 20, period: 1.hour) do |req|
    if req.path == '/friendships' && req.post?
      req.env['rack.session'][:user_id]
    end
  end

  # Throttle message sending
  # Allow 60 messages per minute per user
  throttle('messages/user', limit: 60, period: 1.minute) do |req|
    if req.path.start_with?('/messages') && req.post?
      req.env['rack.session'][:user_id]
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    now = match_data[:epoch_time]
    retry_after = (match_data[:period] - (now % match_data[:period])).to_i    [
      429,
      {
        'Content-Type' => 'text/html',
        'Retry-After' => retry_after.to_s
      },
      ["<html><body><h1>Too Many Requests</h1><p>Please try again in #{retry_after} seconds.</p></body></html>"]
    ]
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [:throttle, :blocklist].include?(req.env['rack.attack.match_type'])
      Rails.logger.warn "[Rack::Attack] Blocked #{req.env['rack.attack.match_type']}: #{req.ip} #{req.request_method} #{req.fullpath}"
    end
  end
end