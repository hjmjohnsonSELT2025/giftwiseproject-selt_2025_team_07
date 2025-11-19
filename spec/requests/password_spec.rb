require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "Password1!"
    )
  end

  before do
    post login_path, params: { email: user.email, password: "Password1!" }
  end

  describe "GET /password/edit" do
    it "renders the edit template" do
      get edit_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Change Password")
    end
  end

  describe "PATCH /password" do
    context "with valid params" do
      it "updates the password with valid params" do
        patch password_path, params: {
          user: {
            current_password: "Password1!",
            password: "NewPass1!",
            password_confirmation: "NewPass1!"
          }
        }

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include("Password updated successfully")
      end

      it "allows login with new password after update" do
        patch password_path, params: {
          user: {
            current_password: "Password1!",
            password: "NewPass1!",
            password_confirmation: "NewPass1!"
          }
        }

        delete logout_path
        post login_path, params: { email: user.email, password: "NewPass1!" }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "with invalid params" do
      it "re-renders when confirmation does not match" do
        patch password_path, params: {
          user: {
            current_password: "Password1!",
            password: "NewPass1!",
            password_confirmation: "WrongPass1!"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Password confirmation")
      end

      it "re-renders when current password is incorrect" do
        patch password_path, params: {
          user: {
            current_password: "WrongOldPass1!",
            password: "NewPass1!",
            password_confirmation: "NewPass1!"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Current password is incorrect")
      end

      it "re-renders when new password is too weak" do
        patch password_path, params: {
          user: {
            current_password: "Password1!",
            password: "weak",
            password_confirmation: "weak"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be at least 8 characters")
      end
    end

    context "OAuth user setting password for first time" do
      let(:oauth_user) do
        user = User.new(name: "OAuth User", email: "oauth@example.com")
        user.skip_password_validation = true
        user.save!
        user.authentications.create!(
          provider: "google_oauth2",
          uid: "123456",
          email: "oauth@example.com",
          name: "OAuth User"
        )
        user
      end

      before do
        delete logout_path
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                             provider: "google_oauth2",
                                                                             uid: "123456",
                                                                             info: { email: "oauth@example.com", name: "OAuth User" }
                                                                           })
        get "/auth/google_oauth2/callback"
      end

      it "allows OAuth user to set password without current password" do
        patch password_path, params: {
          user: {
            password: "NewPass1!",
            password_confirmation: "NewPass1!"
          }
        }

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include("Password updated successfully")
      end

      it "allows OAuth user to login with password after setting it" do
        patch password_path, params: {
          user: {
            password: "NewPass1!",
            password_confirmation: "NewPass1!"
          }
        }

        delete logout_path
        post login_path, params: { email: "oauth@example.com", password: "NewPass1!" }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "authentication required" do
    it "redirects to login when not authenticated" do
      delete logout_path
      get edit_password_path
      expect(response).to redirect_to(login_path)
    end
  end
end