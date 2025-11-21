
# spec/controllers/chatbots_controller_spec.rb
require "rails_helper"

RSpec.describe ChatbotsController, type: :controller do
  let(:user) do
    User.create!(
      name:  "RSpec Chatbot User",
      email: "chatbot-rspec@example.com",
      password:              "Password1!",
      password_confirmation: "Password1!"
    )
  end

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #message basic structure" do
    it "returns JSON with messages and quick_replies keys" do
      post :message, params: {}

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to have_key("messages")
      expect(json).to have_key("quick_replies")
      expect(json["messages"]).to be_an(Array)
      expect(json["quick_replies"]).to be_an(Array)
    end
  end

  describe "POST #message free-text" do
    it "responds with a bot message when user sends text" do
      post :message, params: { text: "hello" }

      json     = JSON.parse(response.body)
      messages = json["messages"]

      expect(messages).to be_an(Array)
      last = messages.last
      expect(last["role"]).to eq("bot")
      expect(last["text"]).to be_present
    end
  end

  describe "POST #message commands" do
    it "resets the conversation on command=reset" do
      post :message, params: { command: "reset" }

      json     = JSON.parse(response.body)
      messages = json["messages"]

      expect(messages.size).to be >= 1
      expect(messages.last["role"]).to eq("bot")
      expect(messages.last["text"]).to include("Conversation restarted")
    end

    it "clears the conversation on command=exit" do
      post :message, params: { text: "hi" }
      expect(JSON.parse(response.body)["messages"]).not_to be_empty

      post :message, params: { command: "exit" }
      json = JSON.parse(response.body)

      expect(json["messages"]).to eq([])
    end
  end

  # ---------- extra easy tests below ----------

  describe "navigation intents" do
    it "shows navigation help when nav_menu intent is sent" do
      post :message, params: { intent: "nav_menu" }

      json     = JSON.parse(response.body)
      messages = json["messages"]
      last     = messages.last

      expect(last["role"]).to eq("bot")
      expect(last["text"]).to include("Navigation help")

      quick_replies = json["quick_replies"]
      intents = quick_replies.map { |qr| qr["intent"] }
      expect(intents).to include("nav_add_event")
    end

    it "answers 'How do I add an event?' intent" do
      post :message, params: { intent: "nav_add_event" }

      json     = JSON.parse(response.body)
      messages = json["messages"]
      last     = messages.last

      expect(last["role"]).to eq("bot")
      expect(last["text"]).to include("To add an event")
    end
  end

  describe "free-text routing helpers" do
    it "answers wishlist question with empty wishlist text" do
      post :message, params: { text: "Show my wishlist" }

      json     = JSON.parse(response.body)
      messages = json["messages"]
      last     = messages.last

      expect(last["role"]).to eq("bot")
      expect(last["text"]).to include("Your wishlist is empty")
    end

    it "answers upcoming events question when there are none" do
      post :message, params: { text: "Show my upcoming events" }

      json     = JSON.parse(response.body)
      messages = json["messages"]
      last     = messages.last

      expect(last["role"]).to eq("bot")
      expect(last["text"]).to include("upcoming events yet")
    end
  end
end
