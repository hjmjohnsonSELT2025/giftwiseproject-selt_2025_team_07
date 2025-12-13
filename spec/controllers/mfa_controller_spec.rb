require 'rails_helper'

RSpec.describe MfaController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }

  describe 'before_action filters' do
    describe 'require_login' do
      it 'redirects to login when not authenticated' do
        get :setup
        expect(response).to redirect_to(login_path)
      end
    end

    describe 'require_password_login' do
      let(:oauth_user) { User.create!(name: 'OAuth User', email: 'oauth@example.com', skip_password_validation: true) }

      before do
        session[:user_id] = oauth_user.id
      end

      it 'redirects OAuth users who try to setup MFA' do
        get :setup
        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:alert]).to eq('You must set a password before enabling MFA')
      end
    end
  end

  describe 'GET #setup' do
    before do
      session[:user_id] = user.id
    end

    context 'when MFA is not enabled' do
      it 'renders setup page' do
        get :setup
        expect(response).to render_template(:setup)
      end

      it 'generates and stores secret in session' do
        get :setup
        expect(session[:mfa_secret]).to be_present
        expect(session[:mfa_secret].length).to be > 0
      end

      it 'assigns provisioning_uri' do
        get :setup
        expect(assigns(:provisioning_uri)).to be_present
        expect(assigns(:provisioning_uri)).to include('otpauth://totp/')
      end

      it 'assigns secret_key' do
        get :setup
        expect(assigns(:secret_key)).to be_present
        expect(assigns(:secret_key)).to eq(session[:mfa_secret])
      end
    end

    context 'when MFA is already enabled' do
      before do
        user.create_mfa_credential!(secret_key: ROTP::Base32.random, enabled: true)
      end

      it 'redirects to profile edit page' do
        get :setup
        expect(response).to redirect_to(edit_profile_path)
      end

      it 'sets alert flash message' do
        get :setup
        expect(flash[:alert]).to eq('MFA is already enabled')
      end
    end
  end

  describe 'POST #enable' do
    before do
      session[:user_id] = user.id
    end

    let(:secret) { ROTP::Base32.random }

    context 'with valid code' do
      before do
        session[:mfa_secret] = secret
      end

      it 'creates MFA credential' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        expect {
          post :enable, params: { code: code }
        }.to change { user.reload.mfa_credential }.from(nil)
      end

      it 'enables MFA' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :enable, params: { code: code }
        expect(user.reload.mfa_enabled?).to be true
      end

      it 'sets enabled_at timestamp' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :enable, params: { code: code }
        expect(user.reload.mfa_credential.enabled_at).to be_within(10.seconds).of(Time.current)
      end

      it 'generates backup codes' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        expect {
          post :enable, params: { code: code }
        }.to change { user.reload.backup_codes.count }.by(10)
      end

      it 'assigns backup codes' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :enable, params: { code: code }
        expect(assigns(:backup_codes)).to be_present
        expect(assigns(:backup_codes).length).to eq(10)
      end

      it 'removes secret from session' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :enable, params: { code: code }
        expect(session[:mfa_secret]).to be_nil
      end

      it 'renders backup_codes template' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now

        post :enable, params: { code: code }
        expect(response).to render_template(:backup_codes)
      end
    end

    context 'with invalid code' do
      before do
        session[:mfa_secret] = secret
      end

      it 'does not create MFA credential' do
        expect {
          post :enable, params: { code: '000000' }
        }.not_to change { MfaCredential.count }
      end

      it 'redirects to setup page' do
        post :enable, params: { code: '000000' }
        expect(response).to redirect_to(setup_mfa_path)
      end

      it 'sets alert flash message' do
        post :enable, params: { code: '000000' }
        expect(flash[:alert]).to eq('Invalid code. Please try again.')
      end
    end

    context 'without secret in session' do
      it 'redirects to setup page' do
        post :enable, params: { code: '123456' }
        expect(response).to redirect_to(setup_mfa_path)
      end

      it 'sets alert flash message' do
        post :enable, params: { code: '123456' }
        expect(flash[:alert]).to eq('Please start the setup process again')
      end
    end

    context 'without code parameter' do
      before do
        session[:mfa_secret] = secret
      end

      it 'redirects to setup page' do
        post :enable, params: { code: '' }
        expect(response).to redirect_to(setup_mfa_path)
      end

      it 'sets alert flash message' do
        post :enable, params: { code: '' }
        expect(flash[:alert]).to eq('Please enter the authentication code')
      end
    end
  end

  describe 'DELETE #disable' do
    before do
      session[:user_id] = user.id
    end

    context 'when MFA is enabled' do
      before do
        user.create_mfa_credential!(secret_key: ROTP::Base32.random, enabled: true)
        BackupCode.generate_codes_for_user(user)
      end

      it 'destroys MFA credential' do
        expect {
          delete :disable
        }.to change { user.reload.mfa_credential }.to(nil)
      end

      it 'destroys all backup codes' do
        expect {
          delete :disable
        }.to change { user.reload.backup_codes.count }.to(0)
      end

      it 'redirects to profile edit page' do
        delete :disable
        expect(response).to redirect_to(edit_profile_path)
      end

      it 'sets success flash message' do
        delete :disable
        expect(flash[:notice]).to eq('MFA has been disabled successfully')
      end
    end

    context 'when MFA is not enabled' do
      it 'redirects to profile edit page' do
        delete :disable
        expect(response).to redirect_to(edit_profile_path)
      end

      it 'sets alert flash message' do
        delete :disable
        expect(flash[:alert]).to eq('MFA is not enabled')
      end
    end
  end
end