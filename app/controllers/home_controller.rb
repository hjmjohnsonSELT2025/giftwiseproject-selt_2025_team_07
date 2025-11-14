class HomeController < ApplicationController
  def index
    if (respond_to?(:user_signed_in?) && user_signed_in?) || respond_to?(:current_user) && current_user
      redirect_to dashboard_path and return
    end
  end
end