class EventRecipient < ApplicationRecord
  belongs_to :event
  belongs_to :recipient
  belongs_to :user
  has_many :gift_ideas, dependent: :destroy
end
