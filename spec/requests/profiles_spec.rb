require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password1!') }

  describe "GET /edit" do
    context 'when user is logged in' do
      before do
        post login_path, params: { email: user.email, password: 'Password1!' }
      end

      it "returns http success" do
        get edit_profile_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not logged in' do
      it "redirects to login" do
        get edit_profile_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /update" do
    context 'when user is logged in' do
      before do
        post login_path, params: { email: user.email, password: 'Password1!' }
      end

      it "redirects to dashboard on success" do
        patch profile_path, params: { user: { name: 'Updated' } }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not logged in' do
      it "redirects to login" do
        patch profile_path, params: { user: { name: 'Updated' } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end