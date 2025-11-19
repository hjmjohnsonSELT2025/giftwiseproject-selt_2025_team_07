class AiGiftSuggestion < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :recipient
  belongs_to :event_recipient

  scope :in_wishlist, -> { where(saved_to_wishlist: true) }
end
