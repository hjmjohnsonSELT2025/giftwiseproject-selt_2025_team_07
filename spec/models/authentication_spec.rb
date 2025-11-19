require 'rails_helper'

RSpec.describe Authentication, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    let(:user) do
      u = User.new(name: 'Test', email: 'test@example.com')
      u.skip_password_validation = true
      u.save!
      u
    end

    subject do
      Authentication.new(
        user: user,
        provider: 'google_oauth2',
        uid: 'abc123xyz',
        email: 'test@example.com',
        name: 'Test'
      )
    end

    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }
    it { should validate_uniqueness_of(:uid).scoped_to(:provider) }
  end

  describe 'creating authentication' do
    let(:user) do
      u = User.new(name: 'Test User', email: 'test@example.com')
      u.skip_password_validation = true
      u.save!
      u
    end

    it 'creates authentication with valid attributes' do
      auth = user.authentications.create!(
        provider: 'google_oauth2',
        uid: '123456',
        email: 'test@example.com',
        name: 'Test User'
      )
      expect(auth).to be_persisted
      expect(auth.provider).to eq('google_oauth2')
      expect(auth.uid).to eq('123456')
    end

    it 'does not allow duplicate uid for same provider' do
      user.authentications.create!(provider: 'google_oauth2', uid: '123', email: 'test@example.com', name: 'Test')
      duplicate = user.authentications.build(provider: 'google_oauth2', uid: '123', email: 'test@example.com', name: 'Test')
      expect(duplicate).not_to be_valid
    end

    it 'allows same uid for different providers' do
      user.authentications.create!(provider: 'google_oauth2', uid: '123', email: 'test@example.com', name: 'Test')
      github_auth = user.authentications.build(provider: 'github', uid: '123', email: 'test@example.com', name: 'Test')
      expect(github_auth).to be_valid
    end
  end

  describe 'deletion' do
    let(:user) do
      u = User.new(name: 'Test User', email: 'test@example.com')
      u.skip_password_validation = true
      u.save!
      u
    end

    it 'deletes authentication when user is deleted' do
      user.authentications.create!(provider: 'google_oauth2', uid: '123', email: 'test@example.com', name: 'Test')
      expect { user.destroy }.to change(Authentication, :count).by(-1)
    end
  end
end