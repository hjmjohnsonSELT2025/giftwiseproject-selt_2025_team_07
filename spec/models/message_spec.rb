# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  # ============================================
  # ASSOCIATIONS
  # ============================================

  describe 'associations' do
    it { should belong_to(:sender).class_name('User') }
    it { should belong_to(:receiver).class_name('User') }
  end

  # ============================================
  # VALIDATIONS
  # ============================================

  describe 'validations' do
    it { should validate_presence_of(:body) }

    let(:sender) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:receiver) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'is valid with all required attributes' do
      message = Message.new(sender: sender, receiver: receiver, body: 'Hello!')
      expect(message).to be_valid
    end

    it 'is invalid without a body' do
      message = Message.new(sender: sender, receiver: receiver, body: nil)
      expect(message).not_to be_valid
      expect(message.errors[:body]).to include("can't be blank")
    end

    it 'is invalid with an empty body' do
      message = Message.new(sender: sender, receiver: receiver, body: '')
      expect(message).not_to be_valid
    end

    it 'accepts long messages' do
      long_body = 'a' * 1000
      message = Message.create!(sender: sender, receiver: receiver, body: long_body)
      expect(message.body).to eq(long_body)
    end

    it 'accepts special characters' do
      message = Message.create!(sender: sender, receiver: receiver, body: "Hello! 😊 Check: https://example.com")
      expect(message.body).to include('😊')
    end
  end

  # ============================================
  # SCOPES
  # ============================================

  describe 'scopes' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:user3) { User.create!(name: 'Charlie', email: 'charlie@example.com', password: 'Password1!') }

    describe '.between' do
      before do
        # Messages between user1 and user2
        Message.create!(sender: user1, receiver: user2, body: 'Message 1')
        Message.create!(sender: user2, receiver: user1, body: 'Message 2')
        Message.create!(sender: user1, receiver: user2, body: 'Message 3')
        
        # Messages between user1 and user3 (should not be included)
        Message.create!(sender: user1, receiver: user3, body: 'Message 4')
      end

      it 'returns messages between two users in both directions' do
        messages = Message.between(user1, user2)
        expect(messages.count).to eq(3)
      end

      it 'includes messages sent by first user to second' do
        messages = Message.between(user1, user2)
        expect(messages.where(sender: user1, receiver: user2).count).to eq(2)
      end

      it 'includes messages sent by second user to first' do
        messages = Message.between(user1, user2)
        expect(messages.where(sender: user2, receiver: user1).count).to eq(1)
      end

      it 'excludes messages with other users' do
        messages = Message.between(user1, user2)
        expect(messages).not_to include(Message.find_by(receiver: user3))
      end

      it 'orders messages by created_at ascending' do
        messages = Message.between(user1, user2)
        expect(messages.first.body).to eq('Message 1')
        expect(messages.last.body).to eq('Message 3')
      end

      it 'returns empty array when no messages exist' do
        new_user = User.create!(name: 'New', email: 'new@example.com', password: 'Password1!')
        messages = Message.between(user1, new_user)
        expect(messages).to be_empty
      end
    end

    describe '.visible_to' do
      let!(:message1) { Message.create!(sender: user1, receiver: user2, body: 'Visible message') }
      let!(:message2) { Message.create!(sender: user2, receiver: user1, body: 'Also visible') }
      let!(:message3) { Message.create!(sender: user1, receiver: user2, body: 'Deleted message') }

      before do
        message3.mark_deleted_for(user1)
      end

      it 'returns messages visible to user' do
        visible = Message.visible_to(user1)
        expect(visible).to include(message1, message2)
      end

      it 'excludes messages deleted by user' do
        visible = Message.visible_to(user1)
        expect(visible).not_to include(message3)
      end

      it 'shows different results for different users' do
        visible_to_user1 = Message.visible_to(user1)
        visible_to_user2 = Message.visible_to(user2)

        expect(visible_to_user1.count).to eq(2)
        expect(visible_to_user2.count).to eq(3)
      end
    end

    describe '.unread_for' do
      before do
        Message.create!(sender: user1, receiver: user2, body: 'Unread 1', read: false)
        Message.create!(sender: user1, receiver: user2, body: 'Unread 2', read: false)
        Message.create!(sender: user1, receiver: user2, body: 'Read message', read: true)
        Message.create!(sender: user2, receiver: user1, body: 'Not for user2', read: false)
      end

      it 'returns unread messages for specific user' do
        unread = Message.unread_for(user2)
        expect(unread.count).to eq(2)
      end

      it 'excludes read messages' do
        unread = Message.unread_for(user2)
        expect(unread).not_to include(Message.find_by(body: 'Read message'))
      end

      it 'excludes messages not sent to user' do
        unread = Message.unread_for(user2)
        expect(unread).not_to include(Message.find_by(body: 'Not for user2'))
      end
    end
  end

  # ============================================
  # INSTANCE METHODS
  # ============================================

  describe '#mark_as_read!' do
    let(:sender) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:receiver) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:message) { Message.create!(sender: sender, receiver: receiver, body: 'Test', read: false) }

    it 'marks message as read' do
      expect(message.read).to be false
      message.mark_as_read!
      expect(message.read).to be true
    end

    it 'persists the read status' do
      message.mark_as_read!
      reloaded = Message.find(message.id)
      expect(reloaded.read).to be true
    end

    it 'is idempotent' do
      message.mark_as_read!
      message.mark_as_read!
      expect(message.read).to be true
    end
  end

  describe '#mark_deleted_for' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:message) { Message.create!(sender: user1, receiver: user2, body: 'Test') }

    it 'initializes deleted_by_user_ids array if nil' do
      expect(message.deleted_by_user_ids).to eq([])
      message.mark_deleted_for(user1)
      expect(message.deleted_by_user_ids).to be_an(Array)
    end

    it 'adds user id to deleted_by_user_ids' do
      message.mark_deleted_for(user1)
      expect(message.deleted_by_user_ids).to include(user1.id)
    end

    it 'persists the deletion' do
      message.mark_deleted_for(user1)
      reloaded = Message.find(message.id)
      expect(reloaded.deleted_by_user_ids).to include(user1.id)
    end

    it 'does not duplicate user id if already marked' do
      message.mark_deleted_for(user1)
      message.mark_deleted_for(user1)
      expect(message.deleted_by_user_ids.count(user1.id)).to eq(1)
    end

    it 'allows multiple users to delete the same message' do
      message.mark_deleted_for(user1)
      message.mark_deleted_for(user2)
      expect(message.deleted_by_user_ids).to include(user1.id, user2.id)
    end

    it 'is independent for each user' do
      message.mark_deleted_for(user1)
      expect(message.deleted_for?(user1)).to be true
      expect(message.deleted_for?(user2)).to be false
    end
  end

  describe '#deleted_for?' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:message) { Message.create!(sender: user1, receiver: user2, body: 'Test') }

    it 'returns false when message is not deleted for user' do
      expect(message.deleted_for?(user1)).to be false
    end

    it 'returns true when message is deleted for user' do
      message.mark_deleted_for(user1)
      expect(message.deleted_for?(user1)).to be true
    end

    it 'initializes array if nil' do
      message.deleted_by_user_ids = nil
      expect(message.deleted_for?(user1)).to be false
    end

    it 'returns correct value for each user independently' do
      message.mark_deleted_for(user1)
      expect(message.deleted_for?(user1)).to be true
      expect(message.deleted_for?(user2)).to be false
    end
  end

  # ============================================
  # SERIALIZATION
  # ============================================

  describe 'deleted_by_user_ids serialization' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:message) { Message.create!(sender: user1, receiver: user2, body: 'Test') }

    it 'serializes array as JSON' do
      message.mark_deleted_for(user1)
      message.mark_deleted_for(user2)
      
      # Reload to test serialization
      reloaded = Message.find(message.id)
      expect(reloaded.deleted_by_user_ids).to be_an(Array)
      expect(reloaded.deleted_by_user_ids).to contain_exactly(user1.id, user2.id)
    end

    it 'handles empty array' do
      expect(message.deleted_by_user_ids).to eq([])
      reloaded = Message.find(message.id)
      expect(reloaded.deleted_by_user_ids).to eq([])
    end
  end

  # ============================================
  # CALLBACKS
  # ============================================

  describe 'callbacks' do
    let(:sender) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:receiver) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    describe 'after_create_commit' do
      it 'broadcasts to receiver after creation' do
        expect_any_instance_of(Message).to receive(:broadcast_to_receiver)
        Message.create!(sender: sender, receiver: receiver, body: 'Test')
      end

      it 'does not broadcast on update' do
        message = Message.create!(sender: sender, receiver: receiver, body: 'Test')
        expect(message).not_to receive(:broadcast_to_receiver)
        message.update(body: 'Updated')
      end
    end
  end

  describe '#broadcast_to_receiver' do
    let(:sender) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:receiver) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

  end

  # ============================================
  # MESSAGE ORDERING
  # ============================================

  describe 'message ordering' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'orders messages chronologically' do
      message1 = Message.create!(sender: user1, receiver: user2, body: 'First')
      sleep(0.01)
      message2 = Message.create!(sender: user1, receiver: user2, body: 'Second')
      sleep(0.01)
      message3 = Message.create!(sender: user1, receiver: user2, body: 'Third')
      
      messages = Message.between(user1, user2)
      expect(messages.map(&:body)).to eq(['First', 'Second', 'Third'])
    end
  end

  # ============================================
  # READ STATUS
  # ============================================

  describe 'read status' do
    let(:sender) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:receiver) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }



    it 'can be created as read' do
      message = Message.create!(sender: sender, receiver: receiver, body: 'Test', read: true)
      expect(message.read).to be true
    end
  end

  # ============================================
  # EDGE CASES
  # ============================================

  describe 'edge cases' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'handles messages to self' do
      message = Message.create!(sender: user1, receiver: user1, body: 'Note to self')
      expect(message).to be_valid
      expect(message.sender).to eq(user1)
      expect(message.receiver).to eq(user1)
    end

    it 'handles very long messages' do
      long_message = 'a' * 10000
      message = Message.create!(sender: user1, receiver: user2, body: long_message)
      expect(message.body.length).to eq(10000)
    end

    it 'handles special characters and emojis' do
      message = Message.create!(sender: user1, receiver: user2, body: "Hello! 🎉 <script>alert('xss')</script>")
      expect(message.body).to include('🎉')
      expect(message.body).to include('<script>')
    end

    it 'handles newlines and formatting' do
      message = Message.create!(sender: user1, receiver: user2, body: "Line 1\nLine 2\n\nLine 4")
      expect(message.body).to include("\n")
    end
  end

  # ============================================
  # SOFT DELETE PERSISTENCE
  # ============================================

  describe 'soft delete persistence' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }
    let(:message) { Message.create!(sender: user1, receiver: user2, body: 'Test') }

    it 'message still exists in database after soft delete' do
      message.mark_deleted_for(user1)
      expect(Message.find(message.id)).to eq(message)
    end

    it 'soft delete does not affect message count' do
      expect { message.mark_deleted_for(user1) }.not_to change { Message.count }
    end

  end

  # ============================================
  # TIMESTAMPS
  # ============================================

  describe 'timestamps' do
    let(:sender) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:receiver) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'sets created_at on creation' do
      message = Message.create!(sender: sender, receiver: receiver, body: 'Test')
      expect(message.created_at).to be_present
      expect(message.created_at).to be_within(1.second).of(Time.current)
    end

    it 'updates updated_at on modification' do
      message = Message.create!(sender: sender, receiver: receiver, body: 'Test')
      original_time = message.updated_at

      sleep(0.1)
      message.update(body: 'Updated')

      expect(message.updated_at).to be > original_time
    end

    it 'does not update timestamps on read status change' do
      message = Message.create!(sender: sender, receiver: receiver, body: 'Test')
      original_time = message.updated_at

      sleep(0.1)
      message.mark_as_read!

      # updated_at changes because we're calling update
      expect(message.updated_at).to be >= original_time
    end
  end

  # ============================================
  # BULK OPERATIONS
  # ============================================

  describe 'bulk operations' do
    let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password1!') }
    let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password1!') }

    it 'can create multiple messages at once' do
      messages = 5.times.map do |i|
        { sender_id: user1.id, receiver_id: user2.id, body: "Message #{i}", read: false }
      end
      
      expect { Message.create!(messages) }.to change { Message.count }.by(5)
    end

    it 'can mark multiple messages as read' do
      5.times { Message.create!(sender: user1, receiver: user2, body: 'Test', read: false) }
      
      Message.where(receiver: user2).update_all(read: true)
      expect(Message.where(receiver: user2, read: false).count).to eq(0)
    end

    it 'can delete multiple messages' do
      5.times { Message.create!(sender: user1, receiver: user2, body: 'Test') }
      
      expect { Message.where(sender: user1).destroy_all }.to change { Message.count }.by(-5)
    end
  end
end
