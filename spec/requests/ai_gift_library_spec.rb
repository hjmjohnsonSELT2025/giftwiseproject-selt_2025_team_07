require "rails_helper"

RSpec.describe "AI Gift Library", type: :request do
  let(:user) { create(:user, email: "test@example.com") }
  let(:other_user) { create(:user, email: "other@example.com") }

  # Owned event (mine)
  let!(:owned_event) { create(:event, user: user, event_name: "Owned Event", event_date: Date.today + 7.days) }
  let!(:owned_recipient) { create(:recipient, user: user, name: "Alex") }
  let!(:owned_event_recipient) { create(:event_recipient, user: user, event: owned_event, recipient: owned_recipient) }

  let!(:owned_saved_suggestion) do
    create(:ai_gift_suggestion,
           user: user,
           event: owned_event,
           recipient: owned_recipient,
           event_recipient: owned_event_recipient,
           title: "Smartwatch",
           category: "Tech"
    )
  end

  let!(:owned_unsaved_suggestion) do
    create(:ai_gift_suggestion,
           user: user,
           event: owned_event,
           recipient: owned_recipient,
           event_recipient: owned_event_recipient,
           title: "Garden Book",
           category: "Books"
    )
  end

  # Collaboration event (collab)
  let!(:collab_event) { create(:event, user: other_user, event_name: "Collab Event", event_date: Date.today + 10.days) }
  let!(:collab_recipient) { create(:recipient, user: other_user, name: "Jithu") }
  let!(:collab_event_recipient) { create(:event_recipient, user: other_user, event: collab_event, recipient: collab_recipient) }

  let!(:collab_suggestion) do
    create(:ai_gift_suggestion,
           user: other_user,
           event: collab_event,
           recipient: collab_recipient,
           event_recipient: collab_event_recipient,
           title: "Chess Set",
           category: "Games"
    )
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)

    # Make collab_event accessible through collaborators
    create(:collaborator,
           event: collab_event,
           user: user,
           status: Collaborator::STATUS_ACCEPTED,
           role: Collaborator::ROLE_CO_PLANNER
    )
  end

  describe "GET /ai_gift_library" do
    it "renders the library successfully" do
      get ai_gift_library_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AI Gift Library")
    end

    it "defaults to mine scope (only owned events)" do
      get ai_gift_library_path
      expect(response.body).to include("Owned Event")
      expect(response.body).not_to include("Collab Event")
      expect(response.body).to include("Smartwatch")
      expect(response.body).not_to include("Chess Set")
    end

    it "shows collab scope events when scope=collab" do
      get ai_gift_library_path, params: { scope: "collab" }
      expect(response.body).to include("Collab Event")
      expect(response.body).not_to include("Owned Event")
      expect(response.body).to include("Chess Set")
      expect(response.body).not_to include("Smartwatch")
    end

    it "shows all accessible events when scope=all" do
      get ai_gift_library_path, params: { scope: "all" }
      expect(response.body).to include("Owned Event")
      expect(response.body).to include("Collab Event")
      expect(response.body).to include("Smartwatch")
      expect(response.body).to include("Chess Set")
    end

    it "filters by event, recipient and saved_only using wishlists join" do
      # Save only one suggestion for current_user
      create(:wishlist, user: user, recipient: owned_recipient, ai_gift_suggestion: owned_saved_suggestion)

      get ai_gift_library_path, params: {
        scope:        "mine",
        event_id:     owned_event.id,
        recipient_id: owned_recipient.id,
        saved_only:   "1",
        sort:         "newest"
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Smartwatch")
      expect(response.body).not_to include("Garden Book")
    end

    it "does not treat saved_to_wishlist boolean as saved_only" do
      # Even if someone sets the boolean, without a Wishlist row it should NOT appear in saved_only
      owned_saved_suggestion.update!(saved_to_wishlist: true)

      get ai_gift_library_path, params: { scope: "mine", saved_only: "1" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Smartwatch")
    end

    it "keeps collab scope when filters are applied (scope persistence)" do
      get ai_gift_library_path, params: { scope: "collab", sort: "newest" }
      expect(response).to have_http_status(:ok)

      # This indirectly validates your view keeps scope param, because controller uses params[:scope]
      expect(response.body).to include("Collab Event")
      expect(response.body).not_to include("Owned Event")
    end
  end
end
