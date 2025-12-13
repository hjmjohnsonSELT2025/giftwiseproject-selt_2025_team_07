class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @upcoming_events = Event
                         .accessible_to(current_user)
                         .upcoming
                         .includes(:recipients)
                         .limit(3)
  end
end
