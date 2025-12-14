class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :ai_gift_suggestion, optional: true
  belongs_to :recipient
  belongs_to :event

  validates :title, presence: true
end
