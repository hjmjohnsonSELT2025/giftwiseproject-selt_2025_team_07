class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :ai_gift_suggestion
  belongs_to :recipient
  belongs_to :event

  validates :ai_gift_suggestion_id, uniqueness: { scope: :cart_id }
end
