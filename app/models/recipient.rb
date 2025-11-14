class Recipient < ApplicationRecord
  belongs_to :user
  has_many :event_recipients, dependent: :destroy
  has_many :events, through: :event_recipients

  validates :name, presence: true
  validates :age, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  RELATIONSHIPS = ['Family', 'Friend', 'Colleague', 'Partner', 'Other'].freeze

  validates :relationship, inclusion: { in: RELATIONSHIPS }, allow_nil: true

  # Get all events for this recipient
  def events_with_details
    event_recipients.includes(:event)
  end
end