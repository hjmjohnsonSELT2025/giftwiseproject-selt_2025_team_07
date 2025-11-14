require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  let(:user) do
    User.create!(
      name:  "Test User",
      email: "user@example.com",
      password: "password"
    )
  end

  before do
    # Stub authentication & current_user
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "assigns up to 3 upcoming events for the current user" do
      # create 4 future events; we expect only first 3 if you use .limit(3)
      4.times do |i|
        Event.create!(
          user: user,
          event_name: "Event #{i}",
          event_date: Date.today + (i + 1),
          budget: 10
        )
      end

      get :index

      expect(assigns(:upcoming_events).count).to eq(3)
      expect(assigns(:upcoming_events).first.event_name).to eq("Event 0")
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end
end
