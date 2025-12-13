
# app/controllers/application_controller.rb
# COMPLETE VERSION - All existing functionality + Security enhancements

class ApplicationController < ActionController::Base
  #   SECURITY: Explicit CSRF protection
  protect_from_forgery with: :exception, prepend: true

  #   SECURITY: Additional security checks
  before_action :verify_authenticity_token
  before_action :check_session_timeout
  before_action :set_security_headers

  # EXISTING: Helper methods
  helper_method :current_user, :user_signed_in?

  # ========================================
  # EXISTING METHODS (NO CHANGES)
  # ========================================

  def current_user
    return nil unless session[:user_id]

    @current_user ||= begin
                        user = User.find_by(id: session[:user_id])

                        #   SECURITY: Check if account is locked
                        if user&.respond_to?(:locked?) && user.locked?
                          reset_session
                          nil
                        else
                          user
                        end
                      end
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      #   SECURITY: Store location for return after login
      store_location_for_return
      redirect_to login_path, alert: "Please log in to continue"
    end
  end

  def require_login
    authenticate_user!
  end

  def after_sign_in_path_for(_resource)
    #   SECURITY: Return to stored location or default to dashboard
    session.delete(:return_to) || dashboard_path
  end

  # ========================================
  #   NEW SECURITY METHODS
  # ========================================

  private

  # Session timeout check - logs users out after 2 hours of inactivity
  def check_session_timeout
    return unless user_signed_in?

    if session[:login_time].present?
      login_time = Time.parse(session[:login_time].to_s) rescue nil

      if login_time && login_time < 2.hours.ago
        reset_session
        redirect_to login_path, alert: "Your session has expired. Please log in again."
        return
      end
    else
      # Set login time if not present
      session[:login_time] = Time.current
    end

    # Update last activity time
    session[:last_activity] = Time.current
  end

  # Set additional security headers
  def set_security_headers
    # Prevent clickjacking
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'

    # Prevent MIME type sniffing
    response.headers['X-Content-Type-Options'] = 'nosniff'

    # Enable XSS filtering
    response.headers['X-XSS-Protection'] = '1; mode=block'

    # Referrer policy
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'

    # Permissions policy
    response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'

    # Force HTTPS in production
    if Rails.env.production?
      response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    end
  end

  # Store the location for redirecting back after login
  def store_location_for_return
    return unless request.get?
    return if request.xhr?
    return if request.path == login_path

    session[:return_to] = request.fullpath
  end

  # Helper method for logging security events (if AuditLog exists)
  def log_security_event(action, details = {})
    return unless defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)

    AuditLog.log_security_event(
      user: current_user,
      action: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      details: details.merge({
                               timestamp: Time.current,
                               session_id: session.id,
                               path: request.path,
                               method: request.method
                             })
    )
  rescue => e
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end

  # Helper for logging resource changes (if AuditLog exists)
  def log_resource_change(resource, action, old_value: nil, new_value: nil)
    return unless defined?(AuditLog) && AuditLog.respond_to?(:log_resource_change)

    AuditLog.log_resource_change(
      user: current_user,
      resource: resource,
      action: action,
      old_value: old_value,
      new_value: new_value
    )
  rescue => e
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end

  # Handle common errors
  rescue_from ActiveRecord::RecordNotFound do |exception|
    log_security_event('record_not_found', {
      model: exception.model,
      id: exception.id
    })

    redirect_to dashboard_path, alert: "The requested resource was not found."
  end

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    log_security_event('csrf_token_invalid')

    reset_session
    redirect_to login_path, alert: "Your session has expired. Please log in again."
  end
end