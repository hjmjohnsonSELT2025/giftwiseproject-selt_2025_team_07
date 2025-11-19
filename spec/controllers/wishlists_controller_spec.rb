require "rails_helper"

RSpec.describe WishlistsController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "Password1!") }
  let(:event) { user.events.create!(event_name: "Birthday", event_date: Date.today + 3.days, budget: 100) }
  let(:recipient) { user.recipients.create!(name: "Mom", relationship: "Mother") }
  let!(:event_recipient) { EventRecipient.create!(user: user, event: event, recipient: recipient) }

  let!(:saved_idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Saved Gift",
      saved_to_wishlist: true
    )
  end

  let!(:unsaved_idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Unsaved Gift",
      saved_to_wishlist: false
    )
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "assigns only saved wishlist items for current_user" do
      get :index

      expect(response).to have_http_status(:ok)
      expect(assigns(:wishlist_items)).to include(saved_idea)
      expect(assigns(:wishlist_items)).not_to include(unsaved_idea)
    end
  end
end
