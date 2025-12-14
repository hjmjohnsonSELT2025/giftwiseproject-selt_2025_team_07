class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user
      token = user.generate_password_reset_token!
      PasswordResetMailer.reset_email(user, token).deliver_now
      flash[:notice] = "Password reset instructions have been sent to #{params[:email]}"
      redirect_to login_path
    else
      flash.now[:alert] = "No account found with that email address"
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @token = PasswordResetToken.find_by(token: params[:token])

    if @token.nil? || @token.used
      flash[:alert] = "Invalid or expired password reset link"
      redirect_to login_path
    elsif @token.expired?
      flash[:alert] = "This password reset link has expired. Please request a new one."
      redirect_to forgot_password_path
    end
  end

  def update
    @token = PasswordResetToken.find_by(token: params[:token])

    if @token.nil? || @token.used || @token.expired?
      flash[:alert] = "Invalid or expired password reset link"
      redirect_to login_path
      return
    end

    user = @token.user
    user.password = params[:user][:password]
    user.password_confirmation = params[:user][:password_confirmation]

    if user.save
      @token.mark_as_used!
      flash[:notice] = "Password successfully reset. Please log in with your new password."
      redirect_to login_path
    else
      flash.now[:alert] = user.errors.full_messages.first
      render :edit, status: :unprocessable_content
    end
  end
end