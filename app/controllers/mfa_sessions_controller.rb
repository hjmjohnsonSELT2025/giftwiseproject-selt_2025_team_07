class MfaSessionsController < ApplicationController
  def new
    unless session[:pending_mfa_user_id]
      redirect_to login_path
    end
  end

  def create
    user = User.find_by(id: session[:pending_mfa_user_id])

    unless user
      redirect_to login_path, alert: "Session expired. Please log in again."
      return
    end

    code = params[:code]

    if user.verify_mfa_code(code)
      session.delete(:pending_mfa_user_id)
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Successfully authenticated"
    else
      flash.now[:alert] = "Invalid authentication code"
      render :new, status: :unprocessable_content
    end
  end

  def verify_backup_code
    user = User.find_by(id: session[:pending_mfa_user_id])

    unless user
      redirect_to login_path, alert: "Session expired. Please log in again."
      return
    end

    code = params[:backup_code]

    if user.verify_backup_code(code)
      session.delete(:pending_mfa_user_id)
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Successfully authenticated with backup code"
    else
      flash.now[:alert] = "Invalid or already used backup code"
      render :new, status: :unprocessable_content
    end
  end
end