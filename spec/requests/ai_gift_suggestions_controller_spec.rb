require "rails_helper"

RSpec.describe AiGiftSuggestionsController, type: :request do
  let(:user) do
    User.create!(name: "Tester", email: "tester@example.com", password: "Password@123")
  end

  let(:event) { user.events.create!(event_name: "Birthday", event_date: Date.today) }

  let(:recipient) do
    user.recipients.create!(name: "Sam", relationship: "Friend")
  end

  let!(:event_recipient) do
    EventRecipient.create!(user: user, event: event, recipient: recipient)
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!).and_return(true)

    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(user)
  end

  # --------------------------------------------------------
  # INDEX
  # --------------------------------------------------------
  describe "GET /events/:event_id/ai_gift_suggestions" do
    it "renders successfully" do
      get event_ai_gift_suggestions_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  # --------------------------------------------------------
  # CREATE ACTION
  # --------------------------------------------------------
  describe "POST create" do
    it "uses stub ideas when ideas blank" do
      suggester = instance_double("Ai::GiftSuggester")
      allow(Ai::GiftSuggester).to receive(:new).and_return(suggester)
      allow(suggester).to receive(:call).and_return([])

      post event_ai_gift_suggestions_path(event),
           params: { recipient_id: recipient.id }

      expect(AiGiftSuggestion.count).to be > 0
      expect(response).to redirect_to(event_ai_gift_suggestions_path(event))
    end

    it "rescues Gemini error & uses fallback" do
      suggester = instance_double("Ai::GiftSuggester")
      allow(Ai::GiftSuggester).to receive(:new).and_return(suggester)
      allow(suggester).to receive(:call).and_raise(Ai::GeminiClient::Error.new("fail"))

      post event_ai_gift_suggestions_path(event),
           params: { recipient_id: recipient.id }

      expect(AiGiftSuggestion.count).to be > 0
      expect(flash[:notice]).to include("fallback")
    end
  end

  # --------------------------------------------------------
  # TOGGLE WISHLIST (POST)
  # --------------------------------------------------------
  describe "POST toggle_wishlist" do
    let!(:suggestion) do
      AiGiftSuggestion.create!(
        user: user, event: event, recipient: recipient,
        event_recipient: event_recipient,
        title: "Gift", description: "desc",
        category: "General", round_type: "initial",
        estimated_price: "$10", saved_to_wishlist: false
      )
    end

    it "toggles ON when from event" do
      post toggle_wishlist_event_ai_gift_suggestion_path(event, suggestion),
           params: { from: "event" }

      expect(suggestion.reload.saved_to_wishlist).to eq(true)
      expect(response).to redirect_to(event_ai_gift_suggestions_path(event, from: "event"))
    end

    it "toggles OFF when from wishlist" do
      suggestion.update!(saved_to_wishlist: true)

      post toggle_wishlist_event_ai_gift_suggestion_path(event, suggestion),
           params: { from: "wishlist" }

      expect(suggestion.reload.saved_to_wishlist).to eq(false)
      expect(response).to redirect_to(wishlists_path)
    end
  end

  # --------------------------------------------------------
  # LIBRARY ACTION
  # --------------------------------------------------------
  describe "GET /ai_gift_library" do
    let!(:s1) do
      AiGiftSuggestion.create!(
        user: user, event: event, recipient: recipient,
        event_recipient: event_recipient,
        title: "Library Gift",
        description: "desc",
        category: "Books",
        round_type: "initial",
        estimated_price: "$12",
        saved_to_wishlist: true
      )
    end

    it "loads with default filters" do
      get ai_gift_library_path
      expect(response).to have_http_status(:ok)
      expect(assigns(:suggestions)).not_to be_nil
      expect(assigns(:recipients)).not_to be_nil
    end

    it "filters by event" do
      get ai_gift_library_path, params: { event_id: event.id }

      expect(assigns(:suggestions).pluck(:event_id)).to all(eq(event.id))
    end

    it "filters by recipient" do
      get ai_gift_library_path, params: { recipient_id: recipient.id }

      expect(assigns(:suggestions).pluck(:recipient_id)).to all(eq(recipient.id))
    end

    it "filters by category" do
      get ai_gift_library_path, params: { category: "Books" }

      expect(assigns(:suggestions).first.category).to eq("Books")
    end

    it "filters saved_only" do
      get ai_gift_library_path, params: { saved_only: "1" }

      expect(assigns(:suggestions).all?(&:saved_to_wishlist)).to eq(true)
    end

    it "supports oldest sort" do
      get ai_gift_library_path, params: { sort: "oldest" }
      expect(assigns(:sort)).to eq("oldest")
    end
  end
end
