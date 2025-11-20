require "rails_helper"

RSpec.describe "AI Gift Library", type: :request do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "Password1!") }

  let(:event) do
    user.events.create!(
      event_name: "Birthday",
      event_date: Date.today + 7.days,
      budget: 100
    )
  end

  let(:recipient) do
    user.recipients.create!(
      name: "Alex",
      relationship: "Friend"
    )
  end

  let!(:event_recipient) do
    EventRecipient.create!(
      user: user,
      event: event,
      recipient: recipient,
      budget_allocated: 50
    )
  end

  let!(:saved_suggestion) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      round_type: "initial",
      title: "Smartwatch",
      description: "Tech gift",
      category: "Tech",
      estimated_price: "$100–$200",
      saved_to_wishlist: true
    )
  end

  let!(:unsaved_suggestion) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      round_type: "initial",
      title: "Garden Book",
      description: "Book gift",
      category: "Books",
      estimated_price: "$20–$40",
      saved_to_wishlist: false
    )
  end

  before do
    # Stub current_user for this request spec
    allow_any_instance_of(ApplicationController).
      to receive(:current_user).
        and_return(user)
  end

  it "renders the library successfully" do
    get ai_gift_library_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AI Gift Library")
  end

  it "filters by event, recipient and saved_only" do
    get ai_gift_library_path, params: {
      event_id:     event.id,
      recipient_id: recipient.id,
      saved_only:   "1",
      sort:         "newest"
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Smartwatch")
    expect(response.body).not_to include("Garden Book")
  end
end
