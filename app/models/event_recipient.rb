class EventRecipient < ApplicationRecord
  belongs_to :event
  belongs_to :recipient
  belongs_to :user

  has_many :ai_gift_suggestions, dependent: :destroy
end
