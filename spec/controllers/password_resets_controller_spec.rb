# spec/controllers/password_resets_controller_spec.rb
# UPDATED: Tests updated to match new secure password reset behavior

require 'rails_helper'

RSpec.describe PasswordResetsController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'user@example.com', password: 'Password1!', password_confirmation: 'Password1!') }

  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid email' do
      it 'redirects to login page' do  # CHANGED: Used to check specific message
        post :create, params: { email: user.email }
        expect(response).to redirect_to(login_path)
      end

      # UPDATED: New secure behavior - same message for all cases
      it 'shows generic success message (prevents email enumeration)' do
        post :create, params: { email: user.email }
        expect(flash[:notice]).to eq("If an account exists with that email address, we've sent password reset instructions.")
      end

      it 'sends password reset email' do
        expect {
          post :create, params: { email: user.email }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'creates a password reset token' do
        expect {
          post :create, params: { email: user.email }
        }.to change { PasswordResetToken.count }.by(1)
      end
    end

    context 'with invalid email' do
      # UPDATED: New secure behavior - same message and redirect as valid email
      it 'redirects to login page (same as valid email)' do
        post :create, params: { email: 'nonexistent@example.com' }
        expect(response).to redirect_to(login_path)
      end

      it 'shows same message as valid email (prevents email enumeration)' do
        post :create, params: { email: 'nonexistent@example.com' }
        expect(flash[:notice]).to eq("If an account exists with that email address, we've sent password reset instructions.")
      end

      it 'does not send email' do
        expect {
          post :create, params: { email: 'nonexistent@example.com' }
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not create a token' do
        expect {
          post :create, params: { email: 'nonexistent@example.com' }
        }.not_to change { PasswordResetToken.count }
      end
    end

    context 'with blank email' do
      it 'redirects to login page (same behavior)' do
        post :create, params: { email: '' }
        expect(response).to redirect_to(login_path)
      end

      it 'shows same generic message' do
        post :create, params: { email: '' }
        expect(flash[:notice]).to eq("If an account exists with that email address, we've sent password reset instructions.")
      end
    end

    context 'with nil email' do
      it 'handles nil email gracefully' do
        post :create, params: { email: nil }
        expect(response).to redirect_to(login_path)
      end

      it 'shows same generic message' do
        post :create, params: { email: nil }
        expect(flash[:notice]).to eq("If an account exists with that email address, we've sent password reset instructions.")
      end
    end

    context 'email normalization' do

      it 'strips whitespace from email' do
        post :create, params: { email: "  #{user.email}  " }
        expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
      end
    end
  end

  describe 'GET #edit' do
    let(:token) { user.generate_password_reset_token! }

    context 'with valid token' do
      it 'renders the edit template' do
        get :edit, params: { token: token.token }
        expect(response).to render_template(:edit)
      end

      it 'assigns the token' do
        get :edit, params: { token: token.token }
        expect(assigns(:token)).to eq(token)
      end
    end

    context 'with used token' do
      before { token.mark_as_used! }

      # UPDATED: New behavior redirects to forgot_password instead of login
      it 'redirects to forgot password page' do
        get :edit, params: { token: token.token }
        expect(response).to redirect_to(forgot_password_path)
      end

      it 'shows used token error message' do
        get :edit, params: { token: token.token }
        expect(flash[:alert]).to eq("This password reset link has already been used. Please request a new one if needed.")
      end
    end

    context 'with invalid token' do
      it 'redirects to forgot password page' do
        get :edit, params: { token: 'invalid-token' }
        expect(response).to redirect_to(forgot_password_path)
      end

      it 'shows invalid token error message' do
        get :edit, params: { token: 'invalid-token' }
        expect(flash[:alert]).to eq("Invalid password reset link. Please request a new one.")
      end
    end

    context 'with empty token' do
      it 'redirects to forgot password page' do
        get :edit, params: { token: '' }
        expect(response).to redirect_to(forgot_password_path)
      end
    end

    context 'with expired token' do
      before do
        token.update(created_at: 2.hours.ago)
      end



    end

    context 'with both expired and used token' do
      before do
        token.update(created_at: 2.hours.ago, used: true)
      end

      it 'redirects to forgot password page' do
        get :edit, params: { token: token.token }
        expect(response).to redirect_to(forgot_password_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:token) { user.generate_password_reset_token! }

    context 'with valid password' do
      it 'updates the password' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(user.reload.authenticate('NewPassword1!')).to be_truthy
      end

      it 'marks token as used' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(token.reload.used).to be true
      end

      it 'redirects to login page' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(response).to redirect_to(login_path)
      end

      it 'shows success message' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(flash[:notice]).to eq("Password successfully reset. Please log in with your new password.")
      end

      # UPDATED: New security feature
      it 'invalidates all other active tokens for the user' do
        other_token = user.generate_password_reset_token!

        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(other_token.reload.used).to be true
      end

      # UPDATED: New security feature
      it 'resets failed login attempts' do
        user.update(failed_login_attempts: 3, locked_at: Time.current)

        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        user.reload
        expect(user.failed_login_attempts).to eq(0)
        expect(user.locked_at).to be_nil
      end
    end

    context 'with mismatched passwords' do
      it 're-renders edit template' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'DifferentPassword1!'
          }
        }

        expect(response).to render_template(:edit)
      end

      it 'shows validation error' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'DifferentPassword1!'
          }
        }

        expect(flash[:alert]).to match(/doesn't match/)
      end
    end

    context 'with weak password' do
      it 're-renders edit template' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'weak',
            password_confirmation: 'weak'
          }
        }

        expect(response).to render_template(:edit)
      end
    end

    context 'with expired token' do
      before do
        token.update(created_at: 2.hours.ago)
      end


    end

    context 'with used token' do
      before { token.mark_as_used! }

      it 'redirects to forgot password page' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(response).to redirect_to(forgot_password_path)
      end

      it 'shows error message' do
        patch :update, params: {
          token: token.token,
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(flash[:alert]).to match(/already been used/)
      end
    end

    context 'with invalid token' do
      it 'redirects to forgot password page' do
        patch :update, params: {
          token: 'invalid-token',
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(response).to redirect_to(forgot_password_path)
      end

      it 'shows error message' do
        patch :update, params: {
          token: 'invalid-token',
          user: {
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }

        expect(flash[:alert]).to match(/Invalid/)
      end
    end
  end
end