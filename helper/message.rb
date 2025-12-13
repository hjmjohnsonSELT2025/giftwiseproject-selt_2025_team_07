class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :receiver, class_name: 'User', foreign_key: 'receiver_id'

  validates :body, presence: true

  scope :between, ->(user1, user2) {
    where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).order(created_at: :asc)
  }

  scope :unread_for, ->(user) {
    where(receiver_id: user.id, read: false)
  }

  after_create_commit do
    broadcast_to_receiver
  end

  def broadcast_to_receiver
    ActionCable.server.broadcast(
      "chat_#{receiver_id}",
      {
        message: MessageSerializer.new(self).as_json,
        sender_id: sender_id
      }
    )
  end

  def mark_as_read!
    update(read: true)
  end
end
