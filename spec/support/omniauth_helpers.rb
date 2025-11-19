module OmniauthHelpers
  def mock_google_auth(email: 'test@example.com', name: 'Test User', uid: '123456')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
       provider: 'google_oauth2',
       uid: uid,
       info: {
         email: email,
         name: name
       },
       credentials: {
         token: 'mock_token',
         refresh_token: 'mock_refresh_token',
         expires_at: Time.now + 1.week
       }
     })
  end

  def mock_google_auth_failure
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
  end

  def reset_omniauth
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end