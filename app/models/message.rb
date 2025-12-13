# frozen_string_literal: true

# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :receiver, class_name: 'User', foreign_key: 'receiver_id'

  validates :body, presence: true

  # CRITICAL FOR SQLITE: Serialize the array
  # This allows Rails to store/retrieve arrays in a string column
  serialize :deleted_by_user_ids, type: Array, coder: JSON

  # Scope to get messages between two users
  scope :between, ->(user1, user2) {
    where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).order(created_at: :asc)
  }

  # Scope to get messages visible to a specific user (not deleted by them)
  # Uses Ruby filtering for precise matching (SQLite-compatible)
  scope :visible_to, ->(user) {
    all.to_a.reject { |message| message.deleted_for?(user) }
  }

  # Scope to get unread messages for a user
  scope :unread_for, ->(user) {
    where(receiver_id: user.id, read: false)
  }

  # Broadcast message to receiver via ActionCable after creation
  after_create_commit do
    broadcast_to_receiver
  end

  # Broadcast message to receiver's WebSocket channel
  def broadcast_to_receiver
    ActionCable.server.broadcast(
      "chat_#{receiver_id}",
      {
        message: MessageSerializer.new(self).as_json,
        sender_id: sender_id
      }
    )
  end

  # Mark message as read
  def mark_as_read!
    update(read: true)
  end

  # Soft delete - mark message as deleted for a specific user
  # This allows each user to "clear" their chat view without affecting the other user
  def mark_deleted_for(user)
    # Initialize array if nil
    self.deleted_by_user_ids ||= []

    # Return if already deleted for this user
    return if deleted_by_user_ids.include?(user.id)

    # Add user to deleted list
    self.deleted_by_user_ids << user.id
    save
  end

  # Check if message is deleted for a specific user
  def deleted_for?(user)
    # Ensure array is initialized
    self.deleted_by_user_ids ||= []
    deleted_by_user_ids.include?(user.id)
  end
end