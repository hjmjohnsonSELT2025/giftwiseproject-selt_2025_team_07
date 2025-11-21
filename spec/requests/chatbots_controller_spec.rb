require "rails_helper"

RSpec.describe ChatbotsController, type: :request do
  let(:user) do
    User.create!(name: "Tester", email: "tester@example.com", password: "Password@123")
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  # ======================================================
  # MESSAGE ROUTING
  # ======================================================
  describe "POST /chatbot/message" do
    it "handles reset command" do
      post "/chatbot/message", params: { command: "reset" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["messages"]).not_to be_empty
    end

    it "handles exit command" do
      post "/chatbot/message", params: { command: "exit" }

      body = JSON.parse(response.body)
      expect(body["messages"]).to eq([])
      expect(body["quick_replies"]).not_to be_empty
    end

    it "handles text input" do
      post "/chatbot/message", params: { text: "wishlist" }

      body = JSON.parse(response.body)
      expect(body["messages"].last["role"]).to eq("bot")
    end

    it "handles intent input" do
      post "/chatbot/message", params: { intent: "nav_menu" }

      body = JSON.parse(response.body)
      expect(body["messages"].last["text"]).to include("Navigation help")
    end

    it "ignores empty text & intent" do
      post "/chatbot/message", params: {}

      body = JSON.parse(response.body)
      expect(body["messages"]).to eq([])
    end

    it "rescues unexpected errors" do
      allow_any_instance_of(ChatbotsController).to receive(:handle_message).and_raise("boom")

      post "/chatbot/message", params: { text: "hello" }

      expect(response).to have_http_status(:internal_server_error)
      body = JSON.parse(response.body)
      expect(body["quick_replies"]).not_to be_empty
    end
  end

  # ======================================================
  # INTENT ROUTING
  # ======================================================
  describe "respond_to_intent" do
    let(:controller) { ChatbotsController.new }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:session).and_return({})
    end

    it "handles nav_menu" do
      expect(controller.send(:respond_to_intent, "nav_menu")).to include("Navigation help")
    end

    it "handles main_menu" do
      expect(controller.send(:respond_to_intent, "main_menu")).to include("Here’s what I can help")
    end

    it "handles summary_upcoming_events" do
      expect(controller.send(:respond_to_intent, "summary_upcoming_events")).to be_a(String)
    end

    it "handles summary_recipients" do
      expect(controller.send(:respond_to_intent, "summary_recipients")).to be_a(String)
    end

    it "handles summary_wishlist" do
      expect(controller.send(:respond_to_intent, "summary_wishlist")).to be_a(String)
    end

    it "handles budgets list" do
      expect(controller.send(:respond_to_intent, "summary_budgets_per_event")).to be_a(String)
    end

    it "handles budget_single_event" do
      expect(controller.send(:respond_to_intent, "budget_single_event")).to include("Choose an event").or include("don’t have any upcoming events")
    end

    it "handles all navigation intents" do
      %w[
        nav_add_event nav_link_recipients nav_add_recipient nav_edit_recipient
        nav_view_wishlist nav_edit_profile nav_change_password nav_view_events
        nav_view_recipients
      ].each do |intent|
        expect(controller.send(:respond_to_intent, intent)).to be_a(String)
      end
    end

    it "handles fallback intent" do
      expect(controller.send(:respond_to_intent, "???")).to include("didn’t understand")
    end

    it "handles budget_event_X" do
      event = user.events.create!(event_name: "Party", event_date: Date.today)
      expect(controller.send(:respond_to_intent, "budget_event_#{event.id}")).to be_a(String)
    end
  end

  # ======================================================
  # FREE-TEXT ROUTING
  # ======================================================
  describe "respond_to_free_text" do
    let(:controller) { ChatbotsController.new }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:session).and_return({})
    end

    it "shows empty-event message when no events exist" do
      expect(controller.send(:respond_to_free_text, "budget single event"))
        .to include("You don’t have any upcoming events")
    end

    it "asks to choose event when events exist" do
      user.events.create!(event_name: "Birthday", event_date: Date.today + 1)

      expect(controller.send(:respond_to_free_text, "budget single event"))
        .to include("Choose an event")
    end

    it { expect(controller.send(:respond_to_free_text, "budget upcoming")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "upcoming events")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "recipient")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "wishlist")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "how do i add an event")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "add a recipient")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "edit profile")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "edit recipient")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "link recipients")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "change password")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "all events")).to be_a(String) }
    it { expect(controller.send(:respond_to_free_text, "all recipients")).to be_a(String) }

    it "falls back to main menu" do
      expect(controller.send(:respond_to_free_text, "random blah blah"))
        .to include("Here’s what I can help")
    end
  end

  # ======================================================
  # QUICK REPLIES
  # ======================================================
  describe "current_quick_replies" do
    let(:controller) { ChatbotsController.new }

    before do
      allow(controller).to receive(:session).and_return({ chatbot_mode: "main" })
    end

    it "returns main quick replies" do
      expect(controller.send(:current_quick_replies).size).to be > 0
    end

    it "returns nav quick replies when mode='nav'" do
      allow(controller).to receive(:session).and_return({ chatbot_mode: "nav" })
      expect(controller.send(:current_quick_replies).size).to be > 5
    end
  end

  # ======================================================
  # DATA HELPERS
  # ======================================================
  describe "data helpers" do
    let(:controller) { ChatbotsController.new }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:session).and_return({})
    end

    it { expect(controller.send(:upcoming_events_summary)).to be_a(String) }
    it { expect(controller.send(:recipients_summary)).to be_a(String) }
    it { expect(controller.send(:wishlist_summary)).to be_a(String) }

    it "safe_upcoming_events_per_event_budget handles errors" do
      allow(controller).to receive(:upcoming_events_per_event_budget).and_raise("boom")

      expect(controller.send(:safe_upcoming_events_per_event_budget))
        .to include("trouble")
    end
  end
end
