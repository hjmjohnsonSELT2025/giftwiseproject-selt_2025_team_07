require "rails_helper"

RSpec.describe GiftIdeasController, type: :controller do
  let(:recipient) { create(:recipient) }
  let!(:event_recipient) { create(:event_recipient, recipient: recipient) }

  describe "POST create" do
    it "creates a gift idea and redirects to recipients index" do
      expect {
        post :create, params: {
          recipient_id: recipient.id,
          gift_idea: { idea: "Watch" }
        }
      }.to change(GiftIdea, :count).by(1)

      expect(response).to redirect_to(recipient_path(recipient))  # NEW
    end

    it "fails validation and re-renders new" do
      post :create, params: {
        recipient_id: recipient.id,
        gift_idea: { idea: "" }
      }

      expect(response.status).to eq(422)
      expect(response).to render_template(:new)
    end
  end
end
