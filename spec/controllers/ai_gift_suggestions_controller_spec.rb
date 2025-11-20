require "rails_helper"

RSpec.describe AiGiftSuggestionsController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "Password1!") }
  let(:event) { user.events.create!(event_name: "Birthday", event_date: Date.today + 3.days, budget: 100) }
  let(:recipient) { user.recipients.create!(name: "Mom", relationship: "Mother") }
  let!(:event_recipient) do
    EventRecipient.create!(user: user, event: event, recipient: recipient)
  end

  let(:fake_suggester) { instance_double(Ai::GiftSuggester, call: [AiGiftSuggestion.new(title: "Test Idea", user: user, event: event, recipient: recipient, event_recipient: event_recipient)]) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "assigns recipients and suggestions and renders template" do
      AiGiftSuggestion.create!(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        title: "Existing Idea"
      )

      get :index, params: { event_id: event.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:recipients)).to include(recipient)
      expect(assigns(:suggestions_by_recipient)[recipient.id].map(&:title)).to include("Existing Idea")
      expect(response).to render_template(:index)
    end
  end

  describe "POST #create" do
    before do
      allow(Ai::GiftSuggester).to receive(:new).and_return(fake_suggester)
    end

    it "calls Ai::GiftSuggester and redirects back to index with notice" do
      post :create, params: {
        event_id: event.id,
        recipient_id: recipient.id,
        round_type: "initial"
      }

      expect(Ai::GiftSuggester).to have_received(:new).with(
        user: user,
        event_recipient: event_recipient
      )

      expect(response).to redirect_to(event_ai_gift_suggestions_path(event))
      expect(flash[:notice]).to match(/Generated 1 ideas for/)
    end
  end

  describe "POST #toggle_wishlist" do
    let!(:idea) do
      AiGiftSuggestion.create!(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        title: "Toggle Gift",
        saved_to_wishlist: false
      )
    end

    it "toggles saved_to_wishlist from false to true" do
      post :toggle_wishlist, params: { event_id: event.id, id: idea.id }

      idea.reload
      expect(idea.saved_to_wishlist).to be true
      expect(response).to redirect_to(event_ai_gift_suggestions_path(event))
      expect(flash[:notice]).to match(/Added/)
    end

    it "toggles saved_to_wishlist from true to false" do
      idea.update!(saved_to_wishlist: true)

      post :toggle_wishlist, params: { event_id: event.id, id: idea.id }

      idea.reload
      expect(idea.saved_to_wishlist).to be false
      expect(response).to redirect_to(event_ai_gift_suggestions_path(event))
      expect(flash[:notice]).to match(/Removed/)
    end
  end
end
