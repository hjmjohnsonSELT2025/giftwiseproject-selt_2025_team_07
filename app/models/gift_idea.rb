# app/models/gift_idea.rb
class GiftIdea < ApplicationRecord
  belongs_to :event_recipient
  delegate :recipient, to: :event_recipient, allow_nil: true
  validates :idea, presence: true
end
