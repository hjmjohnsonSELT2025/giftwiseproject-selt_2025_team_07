class GiftGivenBacklog < ApplicationRecord
  belongs_to :user
  belongs_to :event, optional: true
  belongs_to :recipient
  validates :gift_name, presence: true
  validates :recipient_id, presence: true
  validates :user_id, presence: true

end
