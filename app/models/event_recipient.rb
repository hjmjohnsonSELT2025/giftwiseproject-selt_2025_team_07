class EventRecipient < ApplicationRecord
  belongs_to :event
  belongs_to :recipient
  belongs_to :user
end
