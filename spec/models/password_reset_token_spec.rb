require 'rails_helper'

RSpec.describe PasswordResetToken, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'requires a user' do
      token = build(:password_reset_token, user: nil)
      expect(token).not_to be_valid
    end

    it 'generates token on create' do
      token = create(:password_reset_token)
      expect(token.token).to be_present
    end

    it 'generates expires_at on create' do
      token = create(:password_reset_token)
      expect(token.expires_at).to be_present
    end

    it 'ensures token uniqueness' do
      token1 = create(:password_reset_token)
      user2 = create(:user, email: 'user2@example.com')
      token2 = PasswordResetToken.new(user: user2, token: token1.token)
      token2.valid?
      expect(token2.errors[:token]).to include('has already been taken')
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      context 'on create' do
        it 'generates a token' do
          user = create(:user)
          token = PasswordResetToken.new(user: user)
          expect(token.token).to be_nil
          token.valid?
          expect(token.token).to be_present
          expect(token.token.length).to be >= 32
        end

        it 'sets expiration time to 1 hour from now' do
          user = create(:user)
          token = PasswordResetToken.new(user: user)
          expect(token.expires_at).to be_nil
          token.valid?
          expect(token.expires_at).to be_present
          expect(token.expires_at).to be_within(1.second).of(1.hour.from_now)
        end

        it 'generates URL-safe token' do
          token = create(:password_reset_token)
          expect(token.token).to match(/\A[A-Za-z0-9_-]+\z/)
        end

        it 'generates unique tokens' do
          user = create(:user)
          token1 = create(:password_reset_token, user: user)
          token2 = create(:password_reset_token, user: user)
          expect(token1.token).not_to eq(token2.token)
        end
      end

      context 'on update' do
        it 'does not regenerate token' do
          token = create(:password_reset_token)
          original_token = token.token
          original_expires_at = token.expires_at

          token.update(used: true)

          expect(token.token).to eq(original_token)
          expect(token.expires_at).to eq(original_expires_at)
        end
      end
    end

    describe 'after_initialize' do
      it 'sets used to false by default for new records' do
        user = create(:user)
        token = PasswordResetToken.new(user: user)
        expect(token.used).to eq(false)
      end

      it 'does not override existing used value' do
        user = create(:user)
        token = PasswordResetToken.new(user: user, used: true)
        expect(token.used).to eq(true)
      end

      it 'sets used to false even when initialized with nil' do
        user = create(:user)
        token = PasswordResetToken.new(user: user, used: nil)
        expect(token.used).to eq(false)
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let(:user) { create(:user) }
      let!(:active_token) { PasswordResetToken.create!(user: user, used: false, expires_at: 1.hour.from_now) }
      let!(:used_token) { PasswordResetToken.create!(user: user, used: true, expires_at: 1.hour.from_now) }
      let!(:expired_token) { PasswordResetToken.create!(user: user, used: false, expires_at: 2.hours.ago) }
      let!(:used_and_expired) { PasswordResetToken.create!(user: user, used: true, expires_at: 2.hours.ago) }

      it 'returns only unused and non-expired tokens' do
        active_tokens = PasswordResetToken.active
        expect(active_tokens).to include(active_token)
        expect(active_tokens).not_to include(used_token)
        expect(active_tokens).not_to include(expired_token)
        expect(active_tokens).not_to include(used_and_expired)
      end

      it 'returns empty array when no active tokens exist' do
        PasswordResetToken.destroy_all
        expect(PasswordResetToken.active).to be_empty
      end
    end
  end

  describe '#expired?' do
    it 'returns true if token expired 1 hour ago' do
      token = PasswordResetToken.create!(user: create(:user), expires_at: 1.hour.ago, used: false)
      expect(token.expired?).to be true
    end

    it 'returns true if token expired 1 second ago' do
      token = PasswordResetToken.create!(user: create(:user), expires_at: 1.second.ago, used: false)
      expect(token.expired?).to be true
    end

    it 'returns false if token expires in 1 hour' do
      token = PasswordResetToken.create!(user: create(:user), expires_at: 1.hour.from_now, used: false)
      expect(token.expired?).to be false
    end

    it 'returns false if token expires in 1 second' do
      token = PasswordResetToken.create!(user: create(:user), expires_at: 1.second.from_now, used: false)
      expect(token.expired?).to be false
    end

    it 'returns true for token expiring exactly now' do
      token = PasswordResetToken.create!(user: create(:user), expires_at: Time.current, used: false)
      expect(token.expired?).to be true
    end
  end

  describe '#mark_as_used!' do
    it 'sets used to true' do
      token = create(:password_reset_token, used: false)
      expect { token.mark_as_used! }.to change { token.used }.from(false).to(true)
    end

    it 'persists the change to database' do
      token = create(:password_reset_token, used: false)
      token.mark_as_used!
      expect(token.reload.used).to be true
    end

    it 'raises error if update fails' do
      token = create(:password_reset_token)
      allow(token).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      expect { token.mark_as_used! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not change other attributes' do
      token = create(:password_reset_token, used: false)
      original_token = token.token
      original_expires_at = token.expires_at

      token.mark_as_used!

      expect(token.token).to eq(original_token)
      expect(token.expires_at).to be_within(1.second).of(original_expires_at)
    end
  end

  describe 'token security' do
    it 'generates sufficiently long tokens' do
      token = create(:password_reset_token)
      expect(token.token.length).to be >= 32
    end

    it 'generates cryptographically secure tokens' do
      token1 = create(:password_reset_token)
      token2 = create(:password_reset_token)

      expect(token1.token).not_to eq(token2.token)
      expect(token1.token[0..5]).not_to eq(token2.token[0..5])
    end

    it 'does not allow duplicate tokens' do
      token1 = create(:password_reset_token)
      user2 = create(:user, email: 'user2@example.com')
      token2 = PasswordResetToken.new(user: user2, token: token1.token)

      token2.valid?
      expect(token2.errors[:token]).to include('has already been taken')
    end
  end

  describe 'database constraints' do
    it 'requires user_id' do
      token = build(:password_reset_token, user: nil)
      expect(token).not_to be_valid
    end

    it 'cascades delete when user is deleted' do
      user = create(:user)
      token = create(:password_reset_token, user: user)

      expect { user.destroy }.to change { PasswordResetToken.count }.by(-1)
    end
  end
end