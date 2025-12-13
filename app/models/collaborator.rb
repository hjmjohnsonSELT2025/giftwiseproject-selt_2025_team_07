class Collaborator < ApplicationRecord
  # ---- Roles ----
  ROLE_OWNER      = "owner".freeze
  ROLE_CO_PLANNER = "co_planner".freeze
  ROLE_VIEWER     = "viewer".freeze

  ROLES = [
    ROLE_OWNER,
    ROLE_CO_PLANNER,
    ROLE_VIEWER
  ].freeze

  # ---- Statuses ----
  STATUS_PENDING  = "pending".freeze
  STATUS_ACCEPTED = "accepted".freeze
  STATUS_DECLINED = "declined".freeze

  STATUSES = [
    STATUS_PENDING,
    STATUS_ACCEPTED,
    STATUS_DECLINED
  ].freeze

  # Associations
  belongs_to :event
  belongs_to :user

  # Validations
  validates :role,   presence: true, inclusion: { in: ROLES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes
  scope :pending,  -> { where(status: STATUS_PENDING) }
  scope :accepted, -> { where(status: STATUS_ACCEPTED) }

  # State helpers
  def pending?
    status == STATUS_PENDING
  end

  def accepted?
    status == STATUS_ACCEPTED
  end

  def declined?
    status == STATUS_DECLINED
  end
  # Convenience helpers
  def owner?
    role == ROLE_OWNER
  end

  def co_planner?
    role == ROLE_CO_PLANNER
  end

  def viewer?
    role == ROLE_VIEWER
  end
  def role_label
    case role
    when ROLE_OWNER      then "Owner"
    when ROLE_CO_PLANNER then "Co-Planner"
    when ROLE_VIEWER     then "Viewer"
    else role.to_s.humanize
    end
  end
end
