class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  validates :status, inclusion: { in: %w[pending accepted rejected] }
  validates :user_id, uniqueness: { scope: :friend_id }

  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }

  def accept!
    update(status: 'accepted')
    # Create reciprocal friendship
    Friendship.find_or_create_by(user: friend, friend: user) do |f|
      f.status = 'accepted'
    end
  end

  def reject!
    update(status: 'rejected')
  end
end
