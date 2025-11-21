module RequestAuthenticationHelper
  def login_as(user)
    post "/login", params: {
      email: user.email,
      password: user.password
    }

    # Follow redirect to dashboard after login
    follow_redirect! if response.redirect?
  end
end
