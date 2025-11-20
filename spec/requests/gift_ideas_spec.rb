require "rails_helper"

RSpec.describe "GiftIdeas", type: :request do
  let(:recipient) { create(:recipient) }
  let!(:event_recipient) { create(:event_recipient, recipient: recipient) }

  describe "POST /recipients/:recipient_id/gift_ideas" do
    it "creates a new gift idea and redirects to recipients index" do
      expect {
        post recipient_gift_ideas_path(recipient), params: {
          gift_idea: {
            idea: "Laptop",
            description: "Nice",
            price_estimate: 250,
            link: "http://test.com"
          }
        }
      }.to change(GiftIdea, :count).by(1)

      expect(response).to redirect_to(recipient_path(recipient))
    end

    it "renders new on validation error" do
      post recipient_gift_ideas_path(recipient), params: {
        gift_idea: { idea: "" }
      }

      expect(response.status).to eq(422) # unprocessable_entity
      expect(response.body).to include("Add Gift Idea") # modal title
    end
  end
end
