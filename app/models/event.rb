class Event < ApplicationRecord
  belongs_to :user

  has_many :event_recipients, dependent: :destroy
  has_many :recipients, through: :event_recipients
  has_many :ai_gift_suggestions, dependent: :destroy

  has_many :collaborators, dependent: :destroy
  has_many :collaborating_users, through: :collaborators, source: :user

  validates :event_name, presence: true
  validates :event_date, presence: true
  validate  :event_date_cannot_be_in_past
  validates :budget,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  scope :upcoming, -> { where("event_date >= ?", Date.today).order(event_date: :asc) }
  scope :past,     -> { where("event_date < ?",  Date.today).order(event_date: :desc) }

  # All events the given user can see (owner OR accepted collaborator)
  scope :accessible_to, ->(user) {
    return none unless user

    left_joins(:collaborators)
      .where(
        "events.user_id = :uid OR (collaborators.user_id = :uid AND collaborators.status = :accepted)",
        uid: user.id,
        accepted: Collaborator::STATUS_ACCEPTED
      )
      .distinct
  }

  # ----- basic helpers -----

  def owner?(user)
    user && user_id == user.id
  end

  def recipients_with_details
    event_recipients.includes(:recipient)
  end

  def days_until
    return nil unless event_date
    (event_date - Date.current).to_i
  end

  # ----- collaboration helpers -----

  def collaborator_for(user)
    return nil unless user
    collaborators.find_by(user_id: user.id, status: Collaborator::STATUS_ACCEPTED)
  end

  def role_for(user)
    return nil unless user

    if user_id == user.id && defined?(Collaborator::ROLE_OWNER)
      Collaborator::ROLE_OWNER
    else
      collaborator_for(user)&.role
    end
  end

  # Who can fully manage the event (edit, recipients, collaborators, gifts)
  def can_manage_event?(user)
    return false unless user
    return true  if owner?(user)

    collab = collaborator_for(user)
    collab&.role == Collaborator::ROLE_CO_PLANNER
  end

  # For now, same rule as event management
  def can_manage_gifts?(user)
    can_manage_event?(user)
  end

  # Users who share wishlist toggles for this event (owner + accepted co-planners)
  def gift_planners
    planner_ids =
      [user_id] +
      collaborators
        .where(status: Collaborator::STATUS_ACCEPTED,
               role:   Collaborator::ROLE_CO_PLANNER)
        .pluck(:user_id)

    User.where(id: planner_ids.uniq)
  end

  private

  def event_date_cannot_be_in_past
    if event_date.present? && event_date < Date.today
      errors.add(:event_date, "cannot be in the past")
    end
  end
end
