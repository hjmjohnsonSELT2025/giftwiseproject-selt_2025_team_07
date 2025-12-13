class User < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :recipients, dependent: :destroy
  
  # Friendships
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships, source: :friend, 
           -> { where(friendships: { status: 'accepted' }) }
  
  has_many :pending_friend_requests, -> { pending }, 
           class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :sent_friend_requests, -> { pending }, 
           class_name: 'Friendship', foreign_key: 'user_id'

  # Messages
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', foreign_key: 'receiver_id', dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true

  def friend?(other_user)
    friends.include?(other_user)
  end

  def friend_request_pending_with?(other_user)
    Friendship.exists?(
      user_id: id, friend_id: other_user.id, status: 'pending'
    ) || Friendship.exists?(
      user_id: other_user.id, friend_id: id, status: 'pending'
    )
  end

  def unread_messages_from(user)
    received_messages.where(sender: user, read: false).count
  end

  def online?
    # Implement online status logic
    # You can use Redis or a last_seen_at timestamp
    updated_at > 5.minutes.ago
  end
end
