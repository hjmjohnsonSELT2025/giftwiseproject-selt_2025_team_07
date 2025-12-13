# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Friendship, type: :model do
  # ============================================
  # ASSOCIATIONS
  # ============================================

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:friend).class_name('User') }
  end

  # ============================================
  # VALIDATIONS
  # ============================================

  describe 'validations' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:friend_id) }
    it { should validate_presence_of(:status) }

    describe 'status inclusion validation' do
      it 'accepts valid statuses' do
        friendship = user1.friendships.build(friend: user2, status: 'pending')
        expect(friendship).to be_valid

        friendship.status = 'accepted'
        expect(friendship).to be_valid

        friendship.status = 'rejected'
        expect(friendship).to be_valid
      end

      it 'rejects invalid statuses' do
        friendship = user1.friendships.build(friend: user2, status: 'invalid')
        expect(friendship).not_to be_valid
        expect(friendship.errors[:status]).to include('is not included in the list')
      end
    end

    describe 'uniqueness validation' do
      it 'prevents duplicate friendships' do
        user1.friendships.create!(friend: user2, status: 'pending')
        
        duplicate = user1.friendships.build(friend: user2, status: 'pending')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include('already has a friendship with this user')
      end

      it 'allows friendship with different friends' do
        user3 = User.create!(name: 'Charlie', email: 'charlie@example.com', password: 'Password1!')
        
        user1.friendships.create!(friend: user2, status: 'pending')
        friendship2 = user1.friendships.build(friend: user3, status: 'pending')
        
        expect(friendship2).to be_valid
      end
    end

    describe 'self-friendship validation' do
      it 'prevents user from friending themselves' do
        friendship = user1.friendships.build(friend: user1, status: 'pending')
        expect(friendship).not_to be_valid
        expect(friendship.errors[:friend_id]).to include("can't be the same as user")
      end

      it 'allows friendship with different users' do
        friendship = user1.friendships.build(friend: user2, status: 'pending')
        expect(friendship).to be_valid
      end
    end
  end

  # ============================================
  # SCOPES
  # ============================================

  describe 'scopes' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:user3) { User.create!(name: 'Charlie', email: 'charlie@example.com', password: 'Password1!') }
    let(:user4) { User.create!(name: 'David', email: 'david@example.com', password: 'Password1!') }

    before do
      user1.friendships.create!(friend: user2, status: 'pending')
      user1.friendships.create!(friend: user3, status: 'accepted')
      user1.friendships.create!(friend: user4, status: 'rejected')
    end

    describe '.pending' do
      it 'returns only pending friendships' do
        pending_friendships = user1.friendships.pending
        expect(pending_friendships.count).to eq(1)
        expect(pending_friendships.first.friend).to eq(user2)
        expect(pending_friendships.first.status).to eq('pending')
      end

      it 'excludes accepted friendships' do
        expect(user1.friendships.pending).not_to include(user1.friendships.find_by(friend: user3))
      end

      it 'excludes rejected friendships' do
        expect(user1.friendships.pending).not_to include(user1.friendships.find_by(friend: user4))
      end
    end

    describe '.accepted' do
      it 'returns only accepted friendships' do
        accepted_friendships = user1.friendships.accepted
        expect(accepted_friendships.count).to eq(1)
        expect(accepted_friendships.first.friend).to eq(user3)
        expect(accepted_friendships.first.status).to eq('accepted')
      end

      it 'excludes pending friendships' do
        expect(user1.friendships.accepted).not_to include(user1.friendships.find_by(friend: user2))
      end

      it 'excludes rejected friendships' do
        expect(user1.friendships.accepted).not_to include(user1.friendships.find_by(friend: user4))
      end
    end

    describe '.rejected' do
      it 'returns only rejected friendships' do
        rejected_friendships = user1.friendships.rejected
        expect(rejected_friendships.count).to eq(1)
        expect(rejected_friendships.first.friend).to eq(user4)
        expect(rejected_friendships.first.status).to eq('rejected')
      end

      it 'excludes pending friendships' do
        expect(user1.friendships.rejected).not_to include(user1.friendships.find_by(friend: user2))
      end

      it 'excludes accepted friendships' do
        expect(user1.friendships.rejected).not_to include(user1.friendships.find_by(friend: user3))
      end
    end
  end

  # ============================================
  # STATUS TRANSITIONS
  # ============================================

  describe 'status transitions' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:friendship) { user1.friendships.create!(friend: user2, status: 'pending') }

    it 'can transition from pending to accepted' do
      expect(friendship.status).to eq('pending')
      
      friendship.update!(status: 'accepted')
      expect(friendship.status).to eq('accepted')
    end

    it 'can transition from pending to rejected' do
      expect(friendship.status).to eq('pending')
      
      friendship.update!(status: 'rejected')
      expect(friendship.status).to eq('rejected')
    end

    it 'can transition from accepted back to pending' do
      friendship.update!(status: 'accepted')
      
      friendship.update!(status: 'pending')
      expect(friendship.status).to eq('pending')
    end

    it 'persists status changes' do
      friendship.update!(status: 'accepted')
      
      reloaded = Friendship.find(friendship.id)
      expect(reloaded.status).to eq('accepted')
    end
  end

  # ============================================
  # BIDIRECTIONAL FRIENDSHIPS
  # ============================================

  describe 'bidirectional friendships' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'creates separate friendship records for each direction' do
      friendship1 = user1.friendships.create!(friend: user2, status: 'accepted')
      friendship2 = user2.friendships.create!(friend: user1, status: 'accepted')
      
      expect(friendship1).not_to eq(friendship2)
      expect(friendship1.user).to eq(user1)
      expect(friendship1.friend).to eq(user2)
      expect(friendship2.user).to eq(user2)
      expect(friendship2.friend).to eq(user1)
    end

    it 'allows different statuses for each direction' do
      user1.friendships.create!(friend: user2, status: 'pending')
      user2.friendships.create!(friend: user1, status: 'accepted')
      
      expect(user1.friendships.first.status).to eq('pending')
      expect(user2.friendships.first.status).to eq('accepted')
    end
  end

  # ============================================
  # CASCADE DELETION
  # ============================================

  describe 'deletion behavior' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let!(:friendship) { user1.friendships.create!(friend: user2, status: 'accepted') }

    it 'deletes friendship when destroyed' do
      expect { friendship.destroy }.to change { Friendship.count }.by(-1)
    end

    it 'allows user to exist after friendship deletion' do
      friendship.destroy
      expect(User.find(user1.id)).to eq(user1)
      expect(User.find(user2.id)).to eq(user2)
    end
  end

  # ============================================
  # EDGE CASES
  # ============================================

  describe 'edge cases' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'handles nil status gracefully' do
      friendship = user1.friendships.build(friend: user2, status: nil)
      expect(friendship).not_to be_valid
      expect(friendship.errors[:status]).to include("can't be blank")
    end

    it 'handles empty string status' do
      friendship = user1.friendships.build(friend: user2, status: '')
      expect(friendship).not_to be_valid
      expect(friendship.errors[:status]).to include("can't be blank")
    end

    it 'handles whitespace-only status' do
      friendship = user1.friendships.build(friend: user2, status: '   ')
      expect(friendship).not_to be_valid
    end

    it 'is case-sensitive for status' do
      friendship = user1.friendships.build(friend: user2, status: 'Pending')
      expect(friendship).not_to be_valid
      expect(friendship.errors[:status]).to include('is not included in the list')
    end
  end

  # ============================================
  # QUERY OPTIMIZATION
  # ============================================

  describe 'query optimization' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    

  end

  # ============================================
  # TIMESTAMPS
  # ============================================

  describe 'timestamps' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'sets created_at on creation' do
      friendship = user1.friendships.create!(friend: user2, status: 'pending')
      expect(friendship.created_at).to be_present
      expect(friendship.created_at).to be_within(1.second).of(Time.current)
    end

    it 'updates updated_at on status change' do
      friendship = user1.friendships.create!(friend: user2, status: 'pending')
      original_updated_at = friendship.updated_at
      
      sleep(0.1) # Ensure time difference
      friendship.update!(status: 'accepted')
      
      expect(friendship.updated_at).to be > original_updated_at
    end
  end

  # ============================================
  # BULK OPERATIONS
  # ============================================

  describe 'bulk operations' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:users) do
      5.times.map do |i|
        User.create!(name: "User#{i}", email: "user#{i}@example.com", password: 'Password1!')
      end
    end

    it 'can create multiple friendships at once' do
      friendships = users.map do |user|
        { user_id: user1.id, friend_id: user.id, status: 'pending' }
      end
      
      expect { Friendship.create!(friendships) }.to change { Friendship.count }.by(5)
    end

    it 'can update multiple friendships at once' do
      users.each do |user|
        user1.friendships.create!(friend: user, status: 'pending')
      end
      
      user1.friendships.update_all(status: 'accepted')
      expect(user1.friendships.accepted.count).to eq(5)
    end

    it 'can delete multiple friendships at once' do
      users.each do |user|
        user1.friendships.create!(friend: user, status: 'accepted')
      end
      
      expect { user1.friendships.destroy_all }.to change { Friendship.count }.by(-5)
    end
  end
end
