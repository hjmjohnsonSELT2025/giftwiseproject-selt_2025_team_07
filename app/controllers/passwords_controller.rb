class PasswordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
  end

  def update
    if @user.has_password?
      unless @user.authenticate(params[:user][:current_password])
        @user.errors.add(:current_password, 'is incorrect')
        render :edit, status: :unprocessable_content
        return
      end
    end

    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    if @user.save
      redirect_to dashboard_path, notice: 'Password updated successfully'
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = current_user
  end
end