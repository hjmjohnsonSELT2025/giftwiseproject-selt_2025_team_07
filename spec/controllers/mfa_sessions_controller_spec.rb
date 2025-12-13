require 'rails_helper'

RSpec.describe MfaSessionsController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }
  let(:secret) { ROTP::Base32.random }

  before do
    user.create_mfa_credential!(secret_key: secret, enabled: true)
  end

  describe 'GET #new' do
    context 'with pending MFA user in session' do
      before do
        session[:pending_mfa_user_id] = user.id
      end

      it 'renders new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context 'without pending MFA user in session' do
      it 'redirects to login path' do
        get :new
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid TOTP code' do
      before do
        session[:pending_mfa_user_id] = user.id
      end

      it 'authenticates user' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :create, params: { code: code }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'removes pending_mfa_user_id from session' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :create, params: { code: code }
        expect(session[:pending_mfa_user_id]).to be_nil
      end

      it 'redirects to dashboard' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :create, params: { code: code }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets success flash message' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :create, params: { code: code }
        expect(flash[:notice]).to eq('Successfully authenticated')
      end
    end

    context 'with invalid TOTP code' do
      before do
        session[:pending_mfa_user_id] = user.id
      end

      it 'does not authenticate user' do
        post :create, params: { code: '000000' }
        expect(session[:user_id]).to be_nil
      end

      it 'keeps pending_mfa_user_id in session' do
        post :create, params: { code: '000000' }
        expect(session[:pending_mfa_user_id]).to eq(user.id)
      end

      it 'renders new template' do
        post :create, params: { code: '000000' }
        expect(response).to render_template(:new)
      end

      it 'sets alert flash message' do
        post :create, params: { code: '000000' }
        expect(flash[:alert]).to eq('Invalid authentication code')
      end

      it 'returns unprocessable_content status' do
        post :create, params: { code: '000000' }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'without user in session' do
      it 'redirects to login path' do
        post :create, params: { code: '123456' }
        expect(response).to redirect_to(login_path)
      end

      it 'sets alert flash message' do
        post :create, params: { code: '123456' }
        expect(flash[:alert]).to eq('Session expired. Please log in again.')
      end
    end
  end

  describe 'POST #verify_backup_code' do
    let!(:backup_codes) { BackupCode.generate_codes_for_user(user) }

    context 'with valid backup code' do
      before do
        session[:pending_mfa_user_id] = user.id
      end

      it 'authenticates user' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'removes pending_mfa_user_id from session' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(session[:pending_mfa_user_id]).to be_nil
      end

      it 'marks backup code as used' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(user.backup_codes.reload.first.used).to be true
      end

      it 'redirects to dashboard' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets success flash message' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(flash[:notice]).to eq('Successfully authenticated with backup code')
      end
    end

    context 'with invalid backup code' do
      before do
        session[:pending_mfa_user_id] = user.id
      end

      it 'does not authenticate user' do
        post :verify_backup_code, params: { backup_code: 'INVALID1' }
        expect(session[:user_id]).to be_nil
      end

      it 'keeps pending_mfa_user_id in session' do
        post :verify_backup_code, params: { backup_code: 'INVALID1' }
        expect(session[:pending_mfa_user_id]).to eq(user.id)
      end

      it 'renders new template' do
        post :verify_backup_code, params: { backup_code: 'INVALID1' }
        expect(response).to render_template(:new)
      end

      it 'sets alert flash message' do
        post :verify_backup_code, params: { backup_code: 'INVALID1' }
        expect(flash[:alert]).to eq('Invalid or already used backup code')
      end

      it 'returns unprocessable_content status' do
        post :verify_backup_code, params: { backup_code: 'INVALID1' }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with already used backup code' do
      before do
        session[:pending_mfa_user_id] = user.id
        user.verify_backup_code(backup_codes.first)
      end

      it 'does not authenticate user' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(session[:user_id]).to be_nil
      end

      it 'renders new template' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(response).to render_template(:new)
      end

      it 'sets alert flash message' do
        post :verify_backup_code, params: { backup_code: backup_codes.first }
        expect(flash[:alert]).to eq('Invalid or already used backup code')
      end
    end

    context 'without user in session' do
      it 'redirects to login path' do
        post :verify_backup_code, params: { backup_code: 'TESTCODE' }
        expect(response).to redirect_to(login_path)
      end

      it 'sets alert flash message' do
        post :verify_backup_code, params: { backup_code: 'TESTCODE' }
        expect(flash[:alert]).to eq('Session expired. Please log in again.')
      end
    end
  end
end