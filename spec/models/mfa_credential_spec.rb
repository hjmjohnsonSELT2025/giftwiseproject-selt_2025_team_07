require 'rails_helper'

RSpec.describe MfaCredential, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:secret_key) }

    context 'user_id uniqueness' do
      let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }

      it 'validates uniqueness of user_id' do
        MfaCredential.create!(user: user, secret_key: ROTP::Base32.random)
        duplicate = MfaCredential.new(user: user, secret_key: ROTP::Base32.random)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include('has already been taken')
      end
    end
  end

  describe '#verify_code' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }
    let(:secret) { ROTP::Base32.random }
    let(:mfa_credential) { MfaCredential.create!(user: user, secret_key: secret, enabled: true) }

    context 'when enabled' do
      it 'verifies valid TOTP code' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now
        expect(mfa_credential.verify_code(code)).to be true
      end

      it 'rejects invalid code' do
        expect(mfa_credential.verify_code('000000')).to be false
      end

      it 'accepts code with drift_behind' do
        totp = ROTP::TOTP.new(secret)
        code = totp.at(Time.now - 30)
        expect(mfa_credential.verify_code(code)).to be true
      end

      it 'accepts code with drift_ahead' do
        totp = ROTP::TOTP.new(secret)
        code = totp.at(Time.now + 30)
        expect(mfa_credential.verify_code(code)).to be true
      end
    end

    context 'when not enabled' do
      let(:disabled_credential) { MfaCredential.create!(user: user, secret_key: secret, enabled: false) }

      it 'rejects valid code when MFA is disabled' do
        totp = ROTP::TOTP.new(secret)
        code = totp.now
        expect(disabled_credential.verify_code(code)).to be false
      end
    end
  end

  describe '#provisioning_uri' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }
    let(:secret) { ROTP::Base32.random }
    let(:mfa_credential) { MfaCredential.create!(user: user, secret_key: secret) }

    it 'generates correct provisioning URI' do
      uri = mfa_credential.provisioning_uri(user.email)
      expect(uri).to include('otpauth://totp/')
      expect(uri).to include(CGI.escape(user.email))
      expect(uri).to include('GiftWise')
      expect(uri).to include(secret)
    end

    it 'includes issuer parameter' do
      uri = mfa_credential.provisioning_uri(user.email)
      expect(uri).to include('issuer=GiftWise')
    end
  end
end