class EventRecipient < ApplicationRecord
  belongs_to :event
  belongs_to :recipient
  belongs_to :user   # because you save user_id: current_user.id

  validates :event_id, :recipient_id, :user_id, presence: true
end
