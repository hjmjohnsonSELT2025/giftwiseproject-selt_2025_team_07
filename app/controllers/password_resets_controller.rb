# app/controllers/password_resets_controller.rb
# COMPLETE VERSION - All existing functionality + Security enhancements

class PasswordResetsController < ApplicationController

  # ========================================
  # EXISTING ACTIONS (ENHANCED WITH SECURITY)
  # ========================================

  def new
    # No changes - renders forgot password form
  end

  def create
    # Normalize email
    email = params[:email].to_s.strip.downcase

    user = User.find_by(email: email)

    #   SECURITY: Always show the same message to prevent email enumeration
    # CHANGED FROM: Different messages for found/not found
    # CHANGED TO: Same message always
    flash[:notice] = "If an account exists with that email address, we've sent password reset instructions."

    # Only actually send email if user exists
    if user
      # Check if user has too many active tokens (prevent spam)
      active_tokens_count = user.password_reset_tokens.active.count

      if active_tokens_count >= 3
        Rails.logger.warn "User #{user.id} has #{active_tokens_count} active reset tokens"
        # Still show success message to prevent enumeration
      else
        # Generate new token (EXISTING)
        token = user.generate_password_reset_token!

        # Send email (EXISTING)
        begin
          PasswordResetMailer.reset_email(user, token).deliver_now

          #   SECURITY: Log password reset request (if AuditLog exists)
          if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
            AuditLog.log_security_event(
              user: user,
              action: 'password_reset_requested',
              ip_address: request.remote_ip,
              user_agent: request.user_agent,
              details: { email: email }
            )
          end
        rescue => e
          Rails.logger.error "Failed to send password reset email: #{e.message}"
          # Still show success message to prevent enumeration
        end
      end
    else
      #   SECURITY: Log failed attempt (if AuditLog exists)
      if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
        AuditLog.log_security_event(
          user: nil,
          action: 'password_reset_attempted',
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: {
            email: email,
            reason: 'user_not_found'
          }
        )
      end
    end

    # EXISTING: Redirect to login
    redirect_to login_path
  end

  def edit
    @token = PasswordResetToken.find_by(token: params[:token])

    # EXISTING: Validation checks
    if @token.nil?
      flash[:alert] = "Invalid password reset link. Please request a new one."
      redirect_to forgot_password_path
    elsif @token.used
      flash[:alert] = "This password reset link has already been used. Please request a new one if needed."
      redirect_to forgot_password_path
    elsif @token.expired?
      flash[:alert] = "This password reset link has expired. Please request a new one."
      redirect_to forgot_password_path
    end
  end

  def update
    @token = PasswordResetToken.find_by(token: params[:token])

    # EXISTING: Validate token first
    if @token.nil?
      flash[:alert] = "Invalid password reset link"
      redirect_to forgot_password_path
      return
    end

    if @token.used
      flash[:alert] = "This password reset link has already been used"
      redirect_to forgot_password_path
      return
    end

    if @token.expired?
      flash[:alert] = "This password reset link has expired"
      redirect_to forgot_password_path
      return
    end

    # EXISTING: Get user and update password
    user = @token.user
    user.password = params[:user][:password]
    user.password_confirmation = params[:user][:password_confirmation]

    if user.save
      # EXISTING: Mark this token as used
      @token.mark_as_used!

      #   SECURITY: Invalidate ALL other password reset tokens for this user
      user.password_reset_tokens.active.where.not(id: @token.id).update_all(used: true)

      #   SECURITY: Reset failed login attempts (if method exists)
      user.reset_failed_attempts! if user.respond_to?(:reset_failed_attempts!)

      #   SECURITY: Log the password reset (if AuditLog exists)
      if defined?(AuditLog) && AuditLog.respond_to?(:log_security_event)
        AuditLog.log_security_event(
          user: user,
          action: 'password_reset_completed',
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: {}
        )
      end

      # EXISTING: Success message and redirect
      flash[:notice] = "Password successfully reset. Please log in with your new password."
      redirect_to login_path
    else
      # EXISTING: Show validation errors
      flash.now[:alert] = user.errors.full_messages.join(', ')
      render :edit, status: :unprocessable_content
    end
  end
end