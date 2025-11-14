class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
  end

  def update
    user_params = profile_params

    if user_params[:password].blank? && user_params[:password_confirmation].blank?
      user_params.delete(:password)
      user_params.delete(:password_confirmation)
    end

    if @user.update(user_params)
      redirect_to dashboard_path, notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:name, :email, :date_of_birth, :phone_number, :gender, :occupation, :hobbies, :likes, :dislikes, :password, :password_confirmation)
  end
end