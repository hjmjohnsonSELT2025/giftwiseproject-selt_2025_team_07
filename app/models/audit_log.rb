# app/models/audit_log.rb
# FIXED: Serialize syntax updated to remove deprecation warnings

class AuditLog < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :user, optional: true

  # ========================================
  # SERIALIZATION - FIXED DEPRECATION
  # ========================================
  # OLD (deprecated):
  # serialize :details, JSON
  # serialize :old_value, JSON
  # serialize :new_value, JSON

  # NEW (correct Rails 7.2+ syntax):
  serialize :details, coder: JSON
  serialize :old_value, coder: JSON
  serialize :new_value, coder: JSON

  # ========================================
  # CONSTANTS
  # ========================================

  # Event types
  RESOURCE_AUDIT = 'resource_audit'.freeze
  SECURITY_EVENT = 'security_event'.freeze

  EVENT_TYPES = [RESOURCE_AUDIT, SECURITY_EVENT].freeze

  # Security event actions
  SECURITY_ACTIONS = %w[
    login_success
    login_failure
    logout
    oauth_login_success
    oauth_login_failure
    oauth_auth_failure
    password_reset_requested
    password_reset_attempted
    password_reset_completed
    password_changed
    account_created
    account_updated
    account_deleted
    account_locked
    friend_request_sent
    friend_request_accepted
    friend_request_rejected
    message_sent
    message_deleted
    unauthorized_access_attempt
    csrf_token_invalid
    record_not_found
    suspicious_activity
  ].freeze

  # ========================================
  # VALIDATIONS
  # ========================================
  validates :event_type, inclusion: { in: EVENT_TYPES }, allow_nil: true
  validates :action, presence: true

  # ========================================
  # SCOPES - General
  # ========================================
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_action, ->(action) { where(action: action) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :last_24_hours, -> { where('created_at >= ?', 24.hours.ago) }
  scope :last_7_days, -> { where('created_at >= ?', 7.days.ago) }

  # ========================================
  # SCOPES - Security Events
  # ========================================
  scope :security_events, -> { where(event_type: SECURITY_EVENT) }
  scope :resource_audits, -> { where(event_type: RESOURCE_AUDIT) }
  scope :failed_logins, -> { security_events.where(action: 'login_failure') }
  scope :successful_logins, -> { security_events.where(action: 'login_success') }
  scope :suspicious, -> { security_events.where(action: ['unauthorized_access_attempt', 'suspicious_activity', 'csrf_token_invalid']) }

  # ========================================
  # SCOPES - Resource Audits
  # ========================================
  scope :for_resource, ->(resource) { where(resource_type: resource.class.name, resource_id: resource.id) }

  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_event_type, on: :create

  # ========================================
  # CLASS METHODS - Security Events
  # ========================================

  def self.log_security_event(user:, action:, ip_address:, user_agent: nil, details: {})
    create(
      user: user,
      action: action,
      ip_address: ip_address,
      user_agent: user_agent,
      details: details,
      event_type: SECURITY_EVENT
    )
  rescue => e
    Rails.logger.error("Failed to create security audit log: #{e.message}")
    nil
  end

  def self.suspicious_activity?(ip_address, timeframe = 1.hour)
    failed_count = security_events
                     .failed_logins
                     .where(ip_address: ip_address)
                     .where('created_at >= ?', timeframe.ago)
                     .count

    return true if failed_count >= 5

    unique_users = security_events
                     .where(ip_address: ip_address)
                     .where('created_at >= ?', timeframe.ago)
                     .pluck(:user_id)
                     .compact
                     .uniq
                     .count

    return true if unique_users >= 5

    false
  end

  def self.user_security_summary(user)
    events = security_events.by_user(user)

    {
      total_logins: events.successful_logins.count,
      failed_login_attempts: events.failed_logins.count,
      last_login: events.successful_logins.maximum(:created_at),
      password_changes: events.by_action('password_changed').count,
      last_password_change: events.by_action('password_changed').maximum(:created_at),
      unique_ips: events.last_7_days.pluck(:ip_address).compact.uniq.count,
      suspicious_events: events.suspicious.count
    }
  end

  # ========================================
  # CLASS METHODS - Resource Audits
  # ========================================

  def self.log_resource_change(user:, resource:, action:, old_value: nil, new_value: nil)
    create(
      user: user,
      resource_type: resource.class.name,
      resource_id: resource.id,
      action: action,
      old_value: old_value,
      new_value: new_value,
      event_type: RESOURCE_AUDIT
    )
  rescue => e
    Rails.logger.error("Failed to create resource audit log: #{e.message}")
    nil
  end

  def self.resource_history(resource)
    resource_audits
      .for_resource(resource)
      .recent
  end

  # ========================================
  # INSTANCE METHODS
  # ========================================

  def security_event?
    event_type == SECURITY_EVENT
  end

  def resource_audit?
    event_type == RESOURCE_AUDIT
  end

  def suspicious?
    security_event? &&
      ['unauthorized_access_attempt', 'suspicious_activity', 'csrf_token_invalid'].include?(action)
  end

  def security_relevant?
    security_event? &&
      [
        'login_success',
        'login_failure',
        'password_reset_completed',
        'password_changed',
        'account_deleted',
        'unauthorized_access_attempt',
        'csrf_token_invalid'
      ].include?(action)
  end

  def description
    if security_event?
      security_event_description
    else
      resource_audit_description
    end
  end

  private

  def set_event_type
    return if event_type.present?

    if SECURITY_ACTIONS.include?(action)
      self.event_type = SECURITY_EVENT
    elsif resource_type.present? && resource_id.present?
      self.event_type = RESOURCE_AUDIT
    end
  end

  def security_event_description
    case action
    when 'login_success'
      "#{user&.name || 'Someone'} logged in from #{ip_address}"
    when 'login_failure'
      "Failed login attempt from #{ip_address}"
    when 'password_changed'
      "#{user.name} changed their password"
    when 'friend_request_sent'
      "#{user.name} sent a friend request"
    else
      "#{action.humanize} - #{user&.name || 'Unknown user'}"
    end
  end

  def resource_audit_description
    "#{user&.name || 'System'} #{action} #{resource_type}##{resource_id}"
  end
end