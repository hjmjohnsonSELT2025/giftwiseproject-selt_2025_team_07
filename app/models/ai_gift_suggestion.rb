class AiGiftSuggestion < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :recipient, optional: true
  belongs_to :event_recipient, optional: true

  has_many :wishlists, dependent: :destroy

  # Heart state for a specific user
  def saved_for_user?(user)
    return false unless user
    wishlists.exists?(user_id: user.id)
  end
end
