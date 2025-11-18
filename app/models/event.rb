class Event < ApplicationRecord
  belongs_to :user
  has_many :event_recipients, dependent: :destroy
  has_many :recipients, through: :event_recipients

  validates :event_name, presence: true
  validates :event_date, presence: true
  validate :event_date_cannot_be_in_past
  validates :budget, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :upcoming, -> { where('event_date >= ?', Date.today).order(event_date: :asc) }
  scope :past, -> { where('event_date < ?', Date.today).order(event_date: :desc) }

  def recipients_with_details
    event_recipients.includes(:recipient)
  end

  def days_until
    return nil unless event_date
    (event_date - Date.current).to_i
  end

  private

  def event_date_cannot_be_in_past
    if event_date.present? && event_date < Date.today
      errors.add(:event_date, "cannot be in the past")
    end
  end
end
