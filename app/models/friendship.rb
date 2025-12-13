# frozen_string_literal: true

# app/models/friendship.rb
class Friendship < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  # Validations
  validates :user_id, presence: true
  validates :friend_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected] }
  validates :user_id, uniqueness: { scope: :friend_id, message: "already has a friendship with this user" }

  # Ensure user can't friend themselves
  validate :not_self_friendship

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }

  private

  def not_self_friendship
    if user_id == friend_id
      errors.add(:friend_id, "can't be the same as user")
    end
  end
end