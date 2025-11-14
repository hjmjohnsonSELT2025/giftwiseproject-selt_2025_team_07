require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:recipients).dependent(:destroy) }
    it { should have_many(:events).dependent(:destroy) }
  end

  describe 'validations' do
    subject { User.new(name: 'Test User', email: 'test@example.com', password: 'password123') }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'password authentication' do
    it 'authenticates with correct password' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      )
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      )
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  describe 'email normalization' do
    it 'downcases email before saving' do
      user = User.create!(
        name: 'Test User',
        email: 'TEST@EXAMPLE.COM',
        password: 'password123'
      )
      expect(user.reload.email).to eq('test@example.com')
    end
  end

  describe 'age validation' do
    it 'allows valid age' do
      user = User.new(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        age: 25
      )
      expect(user).to be_valid
    end

    it 'does not allow negative age' do
      user = User.new(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        age: -5
      )
      expect(user).not_to be_valid
      expect(user.errors[:age]).to include('must be greater than 0')
    end

    it 'does not allow zero age' do
      user = User.new(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        age: 0
      )
      expect(user).not_to be_valid
    end

    it 'allows nil age' do
      user = User.new(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        age: nil
      )
      expect(user).to be_valid
    end
  end

  describe 'optional profile fields' do
    it 'creates user without optional fields' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      )
      expect(user).to be_persisted
      expect(user.age).to be_nil
      expect(user.occupation).to be_nil
      expect(user.hobbies).to be_nil
      expect(user.likes).to be_nil
      expect(user.dislikes).to be_nil
    end

    it 'creates user with all optional fields' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        age: 30,
        occupation: 'Developer',
        hobbies: 'Coding, Reading',
        likes: 'Coffee, Tech',
        dislikes: 'Bugs'
      )
      expect(user).to be_persisted
      expect(user.age).to eq(30)
      expect(user.occupation).to eq('Developer')
      expect(user.hobbies).to eq('Coding, Reading')
      expect(user.likes).to eq('Coffee, Tech')
      expect(user.dislikes).to eq('Bugs')
    end
  end

  describe 'email uniqueness' do
    it 'does not allow duplicate emails' do
      User.create!(
        name: 'First User',
        email: 'test@example.com',
        password: 'password123'
      )
      duplicate_user = User.new(
        name: 'Second User',
        email: 'test@example.com',
        password: 'password123'
      )
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end

    it 'treats emails as case insensitive for uniqueness' do
      User.create!(
        name: 'First User',
        email: 'test@example.com',
        password: 'password123'
      )
      duplicate_user = User.new(
        name: 'Second User',
        email: 'TEST@EXAMPLE.COM',
        password: 'password123'
      )
      expect(duplicate_user).not_to be_valid
    end
  end
end