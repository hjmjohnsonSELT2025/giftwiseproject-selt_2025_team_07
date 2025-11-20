class Recipient < ApplicationRecord
  belongs_to :user
  has_many :event_recipients, dependent: :destroy
  has_many :events, through: :event_recipients
  has_many :gift_ideas, through: :event_recipients
  has_many :gift_given_backlogs, dependent: :destroy
  def has_any_event?
    event_recipients.exists?
  end

  GENDERS = ['Male', 'Female', 'Prefer not to say', 'Other'].freeze

  # RELATIONSHIPS = [
  #   "Friend",
  #   "Family",
  #   "Partner",
  #   "Colleague",
  #   "Other"
  # ].freeze

  validates :name, presence: true
  validates :email,
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: "must be a valid email address"
            },
            allow_blank: true

  validates :age,
            numericality: { only_integer: true },
            allow_nil: true

  validates :relationship,
            presence: true

  validates :gender,
            inclusion: { in: GENDERS },
            allow_nil: true

  def events_with_details
    event_recipients.includes(:event)
  end
end
