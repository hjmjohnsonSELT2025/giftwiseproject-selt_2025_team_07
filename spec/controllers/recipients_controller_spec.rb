require "rails_helper"

RSpec.describe RecipientsController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "user@mail.com", password: "Password1!") }
  let(:recipient) { user.recipients.create!(name: "Mani") }

  before do
    session[:user_id] = user.id
  end

  describe "GET #index" do
    it "returns success for logged-in user" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "redirects to login for logged-out user" do
      session[:user_id] = nil
      get :index
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns success" do
      get :show, params: { id: recipient.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #edit" do
    it "returns success" do
      get :edit, params: { id: recipient.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    it "creates a recipient with valid params and redirects to dashboard" do
      expect {
        post :create, params: { recipient: { name: "New Rec", email: "new@example.com" } }
      }.to change(Recipient, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "does not create recipient with invalid params and re-renders new" do
      expect {
        post :create, params: { recipient: { name: "" } }
      }.not_to change(Recipient, :count)

      # assuming controller uses: render :new, status: :unprocessable_entity
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH #update" do
    it "updates a recipient with valid params and redirects to index" do
      patch :update, params: { id: recipient.id, recipient: { name: "Updated" } }
      expect(response).to redirect_to(recipients_path)
      expect(recipient.reload.name).to eq("Updated")
    end

    it "does not update recipient with invalid params and re-renders edit" do
      patch :update, params: { id: recipient.id, recipient: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(recipient.reload.name).to eq("Mani")
    end
  end

  describe "DELETE #destroy" do
    it "deletes a recipient and redirects to index" do
      recipient # create it first
      expect {
        delete :destroy, params: { id: recipient.id }
      }.to change(Recipient, :count).by(-1)

      expect(response).to redirect_to(recipients_path)
    end
  end
end
