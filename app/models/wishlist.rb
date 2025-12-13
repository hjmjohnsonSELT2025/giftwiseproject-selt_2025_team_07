class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :ai_gift_suggestion
  belongs_to :recipient, optional: true

  validates :user_id, uniqueness: { scope: :ai_gift_suggestion_id }
end
