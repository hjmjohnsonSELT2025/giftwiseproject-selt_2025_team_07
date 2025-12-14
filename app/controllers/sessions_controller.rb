class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].downcase)

    if user && !user.has_password?
      flash.now[:alert] = 'This account was created with Google. Please use "Login with Google" or set a password in your profile.'
      render :new, status: :unprocessable_content
      return
    end

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Welcome back, #{user.name}!"
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_content
    end
  end

  def omniauth
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user&.persisted?
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Welcome, #{user.name}!"
    else
      redirect_to login_path, alert: 'Authentication failed. Please try again.'
    end
  end

  def auth_failure
    redirect_to login_path, alert: 'Authentication failed. Please try again.'
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'You have been logged out successfully'
  end
end