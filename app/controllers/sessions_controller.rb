# app/controllers/sessions_controller.rb
# COMPLETE VERSION - All existing functionality + Security enhancements

class SessionsController < ApplicationController

  # ========================================
  # EXISTING ACTIONS (ENHANCED WITH SECURITY)
  # ========================================

  def new
    # No changes - renders login form
  end

  def create
    # Normalize email
    email = params[:email].to_s.strip.downcase

    # Find user
    user = User.find_by(email: email)

    #   SECURITY: Check if account is locked
    if user&.locked?
      flash.now[:alert] = 'Your account has been locked due to too many failed login attempts. Please try again in 30 minutes or reset your password.'
      render :new, status: :locked
      return
    end

    # EXISTING: Check for OAuth-only accounts
    if user && !user.has_password?
      flash.now[:alert] = 'This account was created with Google. Please use "Login with Google" or set a password in your profile.'
      render :new, status: :unprocessable_content
      return
    end

    # Attempt authentication
    if user&.authenticate(params[:password])
      # SUCCESS
      #   SECURITY: Reset failed attempts
      user.reset_failed_attempts!

      #   SECURITY: Regenerate session to prevent session fixation
      reset_session

      # Set new session (EXISTING)
      session[:user_id] = user.id
      #   SECURITY: Track login time for session timeout
      session[:login_time] = Time.current

      #   SECURITY: Log successful login (if AuditLog exists)
      if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
        AuditLog.log_security_event(
          user: user,
          action: 'login_success',
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: { email: email }
        )
      end

      # EXISTING: Redirect with success message
      redirect_to dashboard_path, notice: "Welcome back, #{user.name}!"
    else
      # FAILURE
      #   SECURITY: Increment failed attempts
      if user
        user.increment_failed_attempts!

        #   SECURITY: Log failed login (if AuditLog exists)
        if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
          AuditLog.log_security_event(
            user: user,
            action: 'login_failure',
            ip_address: request.remote_ip,
            user_agent: request.user_agent,
            details: {
              attempted_email: email,
              attempts_count: user.failed_login_attempts
            }
          )
        end
      else
        # User doesn't exist - still log attempt (if AuditLog exists)
        if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
          AuditLog.log_security_event(
            user: nil,
            action: 'login_failure',
            ip_address: request.remote_ip,
            user_agent: request.user_agent,
            details: {
              attempted_email: email,
              reason: 'user_not_found'
            }
          )
        end
      end

      # EXISTING: Show error message (same as before)
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_content
    end
  end

  def omniauth
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user&.persisted?
      #   SECURITY: Regenerate session
      reset_session

      # EXISTING: Set session
      session[:user_id] = user.id
      #   SECURITY: Track login time
      session[:login_time] = Time.current

      #   SECURITY: Log OAuth login (if AuditLog exists)
      if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
        AuditLog.log_security_event(
          user: user,
          action: 'oauth_login_success',
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: { provider: auth.provider }
        )
      end

      # EXISTING: Redirect with success
      redirect_to dashboard_path, notice: "Welcome, #{user.name}!"
    else
      #   SECURITY: Log OAuth failure (if AuditLog exists)
      if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
        AuditLog.log_security_event(
          user: nil,
          action: 'oauth_login_failure',
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: { provider: auth&.provider }
        )
      end

      # EXISTING: Redirect with error
      redirect_to login_path, alert: 'Authentication failed. Please try again.'
    end
  end

  def auth_failure
    #  SECURITY: Log OAuth auth failure (if AuditLog exists)
    if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
      AuditLog.log_security_event(
        user: nil,
        action: 'oauth_auth_failure',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        details: { message: params[:message] }
      )
    end

    # EXISTING: Redirect with error
    redirect_to login_path, alert: 'Authentication failed. Please try again.'
  end

  def destroy
    user = current_user

    #  SECURITY: Log logout (if AuditLog exists)
    if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
      AuditLog.log_security_event(
        user: user,
        action: 'logout',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        details: {}
      )
    end

    #  SECURITY: Clear entire session
    reset_session

    # EXISTING: Redirect with message
    redirect_to root_path, notice: 'You have been logged out successfully'
  end
end