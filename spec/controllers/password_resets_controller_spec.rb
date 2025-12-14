require 'rails_helper'

RSpec.describe PasswordResetsController, type: :controller do
  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:success)
    end

    it 'does not require authentication' do
      get :new
      expect(response).not_to redirect_to(login_path)
    end
  end

  describe 'POST #create' do
    let!(:user) { create(:user, email: 'user@example.com', password: 'OldPass1!', password_confirmation: 'OldPass1!') }

    before do
      ActionMailer::Base.deliveries.clear
    end

    context 'with valid email' do
      it 'finds user case-insensitively' do
        post :create, params: { email: 'USER@EXAMPLE.COM' }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to be_present
      end

      it 'creates a password reset token' do
        expect {
          post :create, params: { email: user.email }
        }.to change(PasswordResetToken, :count).by(1)
      end

      it 'creates token associated with correct user' do
        post :create, params: { email: user.email }
        token = PasswordResetToken.last
        expect(token.user).to eq(user)
      end

      it 'sends a password reset email' do
        expect {
          post :create, params: { email: user.email }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'sends email to correct address' do
        post :create, params: { email: user.email }
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include(user.email)
      end

      it 'sends email from noreply@mygiftwise.online' do
        post :create, params: { email: user.email }
        email = ActionMailer::Base.deliveries.last
        expect(email.from).to include('noreply@mygiftwise.online')
      end

      it 'includes correct subject' do
        post :create, params: { email: user.email }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Reset Your GiftWise Password')
      end

      it 'redirects to login page with success message' do
        post :create, params: { email: user.email }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("Password reset instructions have been sent to #{user.email}")
      end

      it 'allows multiple reset requests for same user' do
        expect {
          post :create, params: { email: user.email }
          post :create, params: { email: user.email }
        }.to change(PasswordResetToken, :count).by(2)
      end

      it 'sends email with working reset link' do
        post :create, params: { email: user.email }
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to match(/reset_password\/[A-Za-z0-9_-]+/)
      end
    end

    context 'with invalid email' do
      it 'does not create a password reset token' do
        expect {
          post :create, params: { email: 'nonexistent@example.com' }
        }.not_to change(PasswordResetToken, :count)
      end

      it 'does not send an email' do
        expect {
          post :create, params: { email: 'nonexistent@example.com' }
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'renders new template with error message' do
        post :create, params: { email: 'nonexistent@example.com' }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to eq("No account found with that email address")
      end

      it 'does not reveal whether email exists (still shows error)' do
        post :create, params: { email: 'hacker@example.com' }
        expect(flash[:alert]).to eq("No account found with that email address")
      end
    end

    context 'with blank email' do
      it 'renders new template with error message' do
        post :create, params: { email: '' }
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("No account found with that email address")
      end

      it 'does not create token for blank email' do
        expect {
          post :create, params: { email: '' }
        }.not_to change(PasswordResetToken, :count)
      end
    end

    context 'with nil email' do
      it 'handles nil email gracefully' do
        post :create, params: { email: nil }
        expect(response).to render_template(:new)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET #edit' do
    let(:user) { create(:user) }

    context 'with valid token' do
      let(:token) { create(:password_reset_token, user: user, used: false) }

      it 'renders the edit template' do
        get :edit, params: { token: token.token }
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:success)
      end

      it 'assigns the token' do
        get :edit, params: { token: token.token }
        expect(assigns(:token)).to eq(token)
      end

      it 'does not mark token as used yet' do
        get :edit, params: { token: token.token }
        expect(token.reload.used).to be false
      end
    end

    context 'with expired token' do
      let(:token) { PasswordResetToken.create!(user: user, used: false, expires_at: 2.hours.ago) }

      it 'redirects to forgot password page' do
        get :edit, params: { token: token.token }
        expect(response).to redirect_to(forgot_password_path)
      end

      it 'shows expiration error message' do
        get :edit, params: { token: token.token }
        expect(flash[:alert]).to eq("This password reset link has expired. Please request a new one.")
      end

      it 'does not render edit form' do
        get :edit, params: { token: token.token }
        expect(response).not_to render_template(:edit)
      end
    end

    context 'with used token' do
      let(:token) { create(:password_reset_token, user: user, used: true) }

      it 'redirects to login page' do
        get :edit, params: { token: token.token }
        expect(response).to redirect_to(login_path)
      end

      it 'shows invalid token error message' do
        get :edit, params: { token: token.token }
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context 'with invalid token' do
      it 'redirects to login page' do
        get :edit, params: { token: 'invalid_token_xyz' }
        expect(response).to redirect_to(login_path)
      end

      it 'shows invalid token error message' do
        get :edit, params: { token: 'invalid_token_xyz' }
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context 'with empty token' do
      it 'redirects to login page' do
        get :edit, params: { token: '' }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'with both expired and used token' do
      let(:token) { PasswordResetToken.create!(user: user, used: true, expires_at: 2.hours.ago) }

      it 'redirects to login page' do
        get :edit, params: { token: token.token }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:user) { create(:user, email: 'testuser@example.com', password: 'OldPassword1!', password_confirmation: 'OldPassword1!') }
    let(:token) { create(:password_reset_token, user: user, used: false) }

    context 'with valid password' do
      let(:valid_params) do
        {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }
      end

      it 'updates the user password' do
        patch :update, params: valid_params
        user.reload
        expect(user.authenticate('NewPassword1!')).to be_truthy
      end

      it 'old password no longer works' do
        patch :update, params: valid_params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_falsey
      end

      it 'marks the token as used' do
        expect {
          patch :update, params: valid_params
        }.to change { token.reload.used }.from(false).to(true)
      end

      it 'persists the used status' do
        patch :update, params: valid_params
        expect(PasswordResetToken.find(token.id).used).to be true
      end

      it 'redirects to login with success message' do
        patch :update, params: valid_params
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("Password successfully reset. Please log in with your new password.")
      end

      it 'allows user to login with new password' do
        patch :update, params: valid_params
        user.reload
        expect(user.authenticate('NewPassword1!')).to be_truthy
      end
    end

    context 'with password missing uppercase' do
      let(:invalid_params) do
        {
          token: token.token,
          user: {
            password: 'password1!',
            password_confirmation: 'password1!'
          }
        }
      end

      it 'does not update the password' do
        patch :update, params: invalid_params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_truthy
        expect(user.authenticate('password1!')).to be_falsey
      end

      it 'does not mark token as used' do
        patch :update, params: invalid_params
        expect(token.reload.used).to be false
      end

      it 'renders edit template with errors' do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to include('uppercase')
      end
    end

    context 'with password missing lowercase' do
      let(:invalid_params) do
        {
          token: token.token,
          user: {
            password: 'PASSWORD1!',
            password_confirmation: 'PASSWORD1!'
          }
        }
      end

      it 'renders edit with error' do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
        expect(flash[:alert]).to include('lowercase')
      end
    end

    context 'with password missing number' do
      let(:invalid_params) do
        {
          token: token.token,
          user: {
            password: 'Password!',
            password_confirmation: 'Password!'
          }
        }
      end

      it 'renders edit with error' do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
        expect(flash[:alert]).to include('number')
      end
    end

    context 'with password missing special character' do
      let(:invalid_params) do
        {
          token: token.token,
          user: {
            password: 'Password1',
            password_confirmation: 'Password1'
          }
        }
      end

      it 'renders edit with error' do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
        expect(flash[:alert]).to include('special character')
      end
    end

    context 'with password too short' do
      let(:invalid_params) do
        {
          token: token.token,
          user: {
            password: 'Pass1!',
            password_confirmation: 'Pass1!'
          }
        }
      end

      it 'renders edit with error' do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
        expect(flash[:alert]).to include('is too short')
      end
    end

    context 'with mismatched passwords' do
      let(:mismatched_params) do
        {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'DifferentPassword1!'
          }
        }
      end

      it 'does not update the password' do
        patch :update, params: mismatched_params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_truthy
        expect(user.authenticate('NewPassword1!')).to be_falsey
      end

      it 'does not mark token as used' do
        patch :update, params: mismatched_params
        expect(token.reload.used).to be false
      end

      it 'renders edit template with error' do
        patch :update, params: mismatched_params
        expect(response).to render_template(:edit)
        expect(flash[:alert]).to include("Password confirmation doesn't match")
      end
    end

    context 'with expired token' do
      let(:expired_token) { PasswordResetToken.create!(user: user, used: false, expires_at: 2.hours.ago) }
      let(:params) do
        {
          token: expired_token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }
      end

      it 'does not update the password' do
        patch :update, params: params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_truthy
        expect(user.authenticate('NewPassword1!')).to be_falsey
      end

      it 'redirects to login with error' do
        patch :update, params: params
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context 'with used token' do
      let(:used_token) { create(:password_reset_token, user: user, used: true) }
      let(:params) do
        {
          token: used_token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }
      end

      it 'does not update the password' do
        patch :update, params: params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_truthy
        expect(user.authenticate('NewPassword1!')).to be_falsey
      end

      it 'redirects to login with error' do
        patch :update, params: params
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context 'with invalid token' do
      let(:params) do
        {
          token: 'invalid_token_abc',
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }
      end

      it 'does not update any user password' do
        patch :update, params: params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_truthy
      end

      it 'redirects to login with error' do
        patch :update, params: params
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context 'with blank password' do
      let(:params) do
        {
          token: token.token,
          user: {
            password: '',
            password_confirmation: ''
          }
        }
      end

      it 'does not update password' do
        patch :update, params: params
        user.reload
        expect(user.authenticate('OldPassword1!')).to be_truthy
      end
    end
  end
end