class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @upcoming_events = current_user
                         .events
                         .upcoming
                         .includes(:recipients)
                         .limit(3)
  end
end
