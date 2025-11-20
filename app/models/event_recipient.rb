class EventRecipient < ApplicationRecord
  belongs_to :event
  belongs_to :recipient
  belongs_to :user
  has_many :gift_ideas, dependent: :destroy

  has_many :ai_gift_suggestions, dependent: :destroy
end
