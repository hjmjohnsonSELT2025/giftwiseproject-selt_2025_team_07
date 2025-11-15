require "rails_helper"

RSpec.describe RecipientsController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "user@mail.com", password: "Password1!") }
  let(:recipient) { user.recipients.create!(name: "Mani") }

  before { session[:user_id] = user.id }

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    it "creates a recipient" do
      expect {
        post :create, params: { recipient: { name: "New Rec" } }
      }.to change(Recipient, :count).by(1)
    end
  end

  describe "PATCH #update" do
    it "updates a recipient" do
      patch :update, params: { id: recipient.id, recipient: { name: "Updated" } }
      expect(recipient.reload.name).to eq("Updated")
    end
  end

  describe "DELETE #destroy" do
    it "deletes a recipient" do
      recipient
      expect {
        delete :destroy, params: { id: recipient.id }
      }.to change(Recipient, :count).by(-1)
    end
  end
end
