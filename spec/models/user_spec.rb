require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:recipients).dependent(:destroy) }
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:authentications).dependent(:destroy) }
  end

  describe 'validations' do
    subject { User.new(name: 'Test User', email: 'test@example.com', password: 'Password1!') }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
  end

  describe 'password validations' do
    it 'requires uppercase, lowercase, number, and special character' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!')
      expect(user).to be_valid
    end

    it 'rejects password without uppercase' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'password1!')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters and include uppercase, lowercase, number, and special character')
    end

    it 'rejects password without lowercase' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'PASSWORD1!')
      expect(user).not_to be_valid
    end

    it 'rejects password without number' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password!')
      expect(user).not_to be_valid
    end

    it 'rejects password without special character' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1')
      expect(user).not_to be_valid
    end

    it 'rejects password shorter than 8 characters' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Pass1!')
      expect(user).not_to be_valid
    end

    it 'allows OAuth users without password' do
      user = User.new(name: 'Test', email: 'test@example.com')
      user.skip_password_validation = true
      expect(user).to be_valid
    end
  end

  describe 'phone number validation' do
    it 'allows valid phone numbers' do
      valid_phones = ['(123) 456-7890', '123-456-7890', '1234567890', '+1 123-456-7890']
      valid_phones.each do |phone|
        user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', phone_number: phone)
        expect(user).to be_valid
      end
    end

    it 'rejects invalid phone numbers' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', phone_number: '123')
      expect(user).not_to be_valid
      expect(user.errors[:phone_number]).to include('is not a valid phone number')
    end

    it 'allows blank phone number' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', phone_number: '')
      expect(user).to be_valid
    end
  end

  describe 'gender validation' do
    it 'allows valid genders' do
      User::VALID_GENDERS.each_with_index do |gender, index|
        user = User.new(name: 'Test', email: "test#{index}@example.com", password: 'Password1!', gender: gender)
        expect(user).to be_valid
      end
    end

    it 'rejects invalid gender' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', gender: 'InvalidGender')
      expect(user).not_to be_valid
      expect(user.errors[:gender]).to include('InvalidGender is not a valid gender')
    end

    it 'allows blank gender' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', gender: '')
      expect(user).to be_valid
    end
  end

  describe 'date of birth validation' do
    it 'allows valid past date' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', date_of_birth: Date.today - 25.years)
      expect(user).to be_valid
    end

    it 'rejects future date' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', date_of_birth: Date.today + 1.day)
      expect(user).not_to be_valid
      expect(user.errors[:date_of_birth]).to include('must be in the past')
    end

    it 'rejects today as date of birth' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!', date_of_birth: Date.today)
      expect(user).not_to be_valid
    end

    it 'allows blank date of birth' do
      user = User.new(name: 'Test', email: 'test@example.com', password: 'Password1!')
      expect(user).to be_valid
    end
  end

  describe 'password authentication' do
    it 'authenticates with correct password' do
      user = User.create!(name: 'Test User', email: 'test@example.com', password: 'Password1!')
      expect(user.authenticate('Password1!')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = User.create!(name: 'Test User', email: 'test@example.com', password: 'Password1!')
      expect(user.authenticate('wrongpassword')).to be_falsey
    end

    it 'returns false when user has no password' do
      user = User.new(name: 'OAuth User', email: 'oauth@example.com')
      user.skip_password_validation = true
      user.save!
      expect(user.authenticate('anypassword')).to be_falsey
    end
  end

  describe 'email normalization' do
    it 'downcases email before saving' do
      user = User.create!(name: 'Test User', email: 'TEST@EXAMPLE.COM', password: 'Password1!')
      expect(user.reload.email).to eq('test@example.com')
    end
  end

  describe 'optional profile fields' do
    it 'creates user without optional fields' do
      user = User.create!(name: 'Test User', email: 'test@example.com', password: 'Password1!')
      expect(user).to be_persisted
      expect(user.date_of_birth).to be_nil
      expect(user.phone_number).to be_nil
      expect(user.gender).to be_nil
      expect(user.occupation).to be_nil
      expect(user.hobbies).to be_nil
      expect(user.likes).to be_nil
      expect(user.dislikes).to be_nil
    end

    it 'creates user with all optional fields' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password1!',
        date_of_birth: Date.new(1990, 1, 1),
        phone_number: '(123) 456-7890',
        gender: 'Male',
        occupation: 'Developer',
        hobbies: 'Coding, Reading',
        likes: 'Coffee, Tech',
        dislikes: 'Bugs'
      )
      expect(user).to be_persisted
      expect(user.date_of_birth).to eq(Date.new(1990, 1, 1))
      expect(user.phone_number).to eq('(123) 456-7890')
      expect(user.gender).to eq('Male')
      expect(user.occupation).to eq('Developer')
      expect(user.hobbies).to eq('Coding, Reading')
      expect(user.likes).to eq('Coffee, Tech')
      expect(user.dislikes).to eq('Bugs')
    end
  end

  describe 'email uniqueness' do
    it 'does not allow duplicate emails' do
      User.create!(name: 'First User', email: 'test@example.com', password: 'Password1!')
      duplicate_user = User.new(name: 'Second User', email: 'test@example.com', password: 'Password1!')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end

    it 'treats emails as case insensitive for uniqueness' do
      User.create!(name: 'First User', email: 'test@example.com', password: 'Password1!')
      duplicate_user = User.new(name: 'Second User', email: 'TEST@EXAMPLE.COM', password: 'Password1!')
      expect(duplicate_user).not_to be_valid
    end
  end

  describe 'password update' do
    let(:user) { User.create!(name: 'Test', email: 'test@example.com', password: 'Password1!') }

    it 'allows update without changing password' do
      user.name = 'Updated Name'
      user.password = nil
      expect(user).to be_valid
    end

    it 'validates password format when password is provided' do
      user.password = 'weak'
      user.password_confirmation = 'weak'
      expect(user).not_to be_valid
    end

    it 'validates password confirmation when password is provided' do
      user.password = 'NewPass1!'
      user.password_confirmation = 'Different1!'
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end

    it 'updates password successfully with matching confirmation' do
      user.password = 'NewPass1!'
      user.password_confirmation = 'NewPass1!'
      expect(user).to be_valid
      user.save
      expect(user.authenticate('NewPass1!')).to eq(user)
    end
  end

  describe '#age' do
    it 'calculates age from date of birth' do
      dob = 25.years.ago.to_date
      user = User.create!(
        name: 'Test',
        email: 'test@example.com',
        password: 'Password1!',
        date_of_birth: dob
      )
      expect(user.age).to be_between(24, 25)
    end

    it 'returns nil when date of birth is not set' do
      user = User.create!(name: 'Test', email: 'test@example.com', password: 'Password1!')
      expect(user.age).to be_nil
    end
  end

  describe '.from_omniauth' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
                               provider: 'google_oauth2',
                               uid: '123456',
                               info: {
                                 email: 'oauth@example.com',
                                 name: 'OAuth User'
                               }
                             })
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect {
          User.from_omniauth(auth_hash)
        }.to change(User, :count).by(1)
      end

      it 'creates user with correct attributes' do
        user = User.from_omniauth(auth_hash)
        expect(user.name).to eq('OAuth User')
        expect(user.email).to eq('oauth@example.com')
        expect(user.has_password?).to be_falsey
      end

      it 'creates authentication record' do
        user = User.from_omniauth(auth_hash)
        expect(user.authentications.count).to eq(1)
        expect(user.authentications.first.provider).to eq('google_oauth2')
        expect(user.authentications.first.uid).to eq('123456')
      end

      it 'downcases email' do
        auth_hash.info.email = 'OAUTH@EXAMPLE.COM'
        user = User.from_omniauth(auth_hash)
        expect(user.email).to eq('oauth@example.com')
      end
    end

    context 'when user exists with same email' do
      let!(:existing_user) do
        User.create!(name: 'Existing', email: 'oauth@example.com', password: 'Password1!')
      end

      it 'does not create a new user' do
        expect {
          User.from_omniauth(auth_hash)
        }.not_to change(User, :count)
      end

      it 'returns the existing user' do
        user = User.from_omniauth(auth_hash)
        expect(user.id).to eq(existing_user.id)
      end

      it 'creates authentication record for existing user' do
        user = User.from_omniauth(auth_hash)
        expect(user.authentications.count).to eq(1)
        expect(user.authentications.first.provider).to eq('google_oauth2')
      end

      it 'does not duplicate authentication records' do
        User.from_omniauth(auth_hash)
        user = User.from_omniauth(auth_hash)
        expect(user.authentications.count).to eq(1)
      end
    end

    context 'when user has multiple OAuth providers' do
      let!(:existing_user) do
        user = User.new(name: 'Multi OAuth', email: 'multi@example.com')
        user.skip_password_validation = true
        user.save!
        user.authentications.create!(provider: 'github', uid: '999', email: 'multi@example.com', name: 'Multi OAuth')
        user
      end

      it 'adds new provider authentication' do
        user = User.from_omniauth(auth_hash.merge(info: { email: 'multi@example.com', name: 'Multi OAuth' }))
        expect(user.authentications.count).to eq(2)
        expect(user.authentications.pluck(:provider)).to contain_exactly('github', 'google_oauth2')
      end
    end
  end

  describe '#has_password?' do
    it 'returns true when user has password' do
      user = User.create!(name: 'Test', email: 'test@example.com', password: 'Password1!')
      expect(user.has_password?).to be_truthy
    end

    it 'returns false when user has no password' do
      user = User.new(name: 'OAuth User', email: 'oauth@example.com')
      user.skip_password_validation = true
      user.save!
      expect(user.has_password?).to be_falsey
    end
  end

  describe '#oauth_user?' do
    it 'returns true when user has OAuth authentications' do
      user = User.new(name: 'OAuth User', email: 'oauth@example.com')
      user.skip_password_validation = true
      user.save!
      user.authentications.create!(provider: 'google_oauth2', uid: '123', email: 'oauth@example.com', name: 'OAuth User')
      expect(user.oauth_user?).to be_truthy
    end

    it 'returns false when user has no OAuth authentications' do
      user = User.create!(name: 'Regular User', email: 'regular@example.com', password: 'Password1!')
      expect(user.oauth_user?).to be_falsey
    end
  end
end