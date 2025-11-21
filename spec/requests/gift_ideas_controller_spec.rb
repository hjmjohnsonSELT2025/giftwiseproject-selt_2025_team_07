require "rails_helper"

RSpec.describe GiftIdeasController, type: :request do
  let(:user) do
    User.create!(
      name: "Tester",
      email: "tester@example.com",
      password: "Password@123"
    )
  end

  let(:recipient) do
    user.recipients.create!(
      name: "Sam",
      relationship: "Friend"
    )
  end

  let(:event) do
    user.events.create!(
      event_name: "Birthday",
      event_date: Date.today
    )
  end

  let!(:event_recipient) do
    EventRecipient.create!(
      user: user,
      event: event,
      recipient: recipient
    )
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!)
            .and_return(true)

    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
            .and_return(user)
  end

  # ------------------------------------------------------------
  # GET new
  # ------------------------------------------------------------
  describe "GET /recipients/:recipient_id/gift_ideas/new" do
    it "renders successfully" do
      get new_recipient_gift_idea_path(recipient)

      expect(response).to have_http_status(:ok)
      expect(assigns(:gift_idea)).to be_a(GiftIdea)
    end
  end

  # ------------------------------------------------------------
  # POST create (success + failure)
  # ------------------------------------------------------------
  describe "POST /recipients/:recipient_id/gift_ideas" do
    let(:valid_params) do
      {
        gift_idea: {
          idea: "Laptop",
          description: "A powerful laptop",
          price_estimate: 1200,
          link: "https://example.com/laptop"
        }
      }
    end

    it "creates a gift idea and redirects on success" do
      expect {
        post recipient_gift_ideas_path(recipient), params: valid_params
      }.to change { GiftIdea.count }.by(1)

      expect(response).to redirect_to(recipient_path(recipient))
      expect(flash[:notice]).to eq("Gift idea added successfully.")
    end

    it "renders new with errors when invalid" do
      invalid_params = { gift_idea: { idea: "" } }

      post recipient_gift_ideas_path(recipient), params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to eq("Please fix the errors below.")
      expect(response.body).to include("Gift")
    end
  end

  # ------------------------------------------------------------
  # DELETE destroy (turbo_stream + html)
  # ------------------------------------------------------------
  describe "DELETE /recipients/:recipient_id/gift_ideas/:id" do
    let!(:gift_idea) do
      GiftIdea.create!(
        idea: "Test Idea",
        description: "desc",
        price_estimate: 20,
        link: "http://example.com",
        event_recipient: event_recipient
      )
    end

    it "removes gift idea via turbo_stream" do
      expect {
        delete recipient_gift_idea_path(recipient, gift_idea),
               headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change { GiftIdea.count }.by(-1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("gift_idea_#{gift_idea.id}")
    end

    it "removes gift idea via HTML and redirects" do
      gift_idea2 = GiftIdea.create!(
        idea: "Another",
        description: "desc",
        price_estimate: 50,
        link: "http://example.com",
        event_recipient: event_recipient
      )

      expect {
        delete recipient_gift_idea_path(recipient, gift_idea2)
      }.to change { GiftIdea.count }.by(-1)

      expect(response).to redirect_to(recipients_path)
      expect(flash[:notice]).to eq("Gift idea removed successfully.")
    end
  end
end
