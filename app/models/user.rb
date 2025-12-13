class User < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  has_many :recipients, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :event_recipients, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy
  has_many :ai_gift_suggestions, dependent: :destroy
  has_many :wishlists, dependent: :destroy

  # MFA
  has_one :mfa_credential, dependent: :destroy
  has_many :backup_codes, dependent: :destroy

  # Friendships
  has_many :friendships, dependent: :destroy
  has_many :friends,
           -> { where(friendships: { status: 'accepted' }) },
           through: :friendships,
           source: :friend

  has_many :received_friendships,
           class_name: 'Friendship',
           foreign_key: 'friend_id',
           dependent: :destroy

  has_many :pending_friend_requests,
           -> { pending },
           class_name: 'Friendship',
           foreign_key: 'friend_id'

  has_many :sent_friend_requests,
           -> { pending },
           class_name: 'Friendship',
           foreign_key: 'user_id'

  # Messages
  has_many :sent_messages,
           class_name: 'Message',
           foreign_key: 'sender_id',
           dependent: :destroy

  has_many :received_messages,
           class_name: 'Message',
           foreign_key: 'receiver_id',
           dependent: :destroy

  # Collaborations
  has_many :collaborators,
           class_name: 'Collaborator',
           dependent: :destroy

  has_many :collaborating_events,
           through: :collaborators,
           source: :event

  has_many :pending_collaboration_requests,
           -> { pending },
           class_name: 'Collaborator',
           foreign_key: :user_id

  # ========================================
  # ATTR ACCESSORS
  # ========================================
  attr_accessor :password_confirmation
  attr_accessor :skip_password_validation
  attr_reader :password

  # ========================================
  # CONSTANTS
  # ========================================
  VALID_PHONE_REGEX = /\A(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}\z/
  VALID_GENDERS = ['Male', 'Female', 'Prefer not to say', 'Other']

  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 30.minutes

  # ========================================
  # VALIDATIONS
  # ========================================
  validates :name, presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
            confirmation: true,
            if: -> { password.present? }

  validates :phone_number,
            format: { with: VALID_PHONE_REGEX },
            allow_blank: true

  validates :gender,
            inclusion: { in: VALID_GENDERS },
            allow_blank: true

  validates :date_of_birth,
            comparison: { less_than: Date.today },
            allow_blank: true

  validate :password_complexity, if: :password_required?

  # ========================================
  # CALLBACKS
  # ========================================
  before_save :downcase_email
  before_save :hash_password, if: -> { @password.present? }

  # ========================================
  # CLASS METHODS
  # ========================================
  def self.from_omniauth(auth)
    return nil unless auth&.info&.email

    email = auth.info.email.downcase
    user = User.find_or_initialize_by(email: email)

    if user.new_record?
      user.name = auth.info.name
      user.skip_password_validation = true
      user.save!
    end

    user.authentications.find_or_create_by!(
      provider: auth.provider,
      uid: auth.uid
    ) do |a|
      a.email = auth.info.email
      a.name = auth.info.name
    end

    user
  end

  # ========================================
  # INSTANCE METHODS
  # ========================================
  def password=(new_password)
    @password = new_password
  end

  def authenticate(password_attempt)
    return false if password_db.blank?
    BCrypt::Password.new(password_db) == password_attempt ? self : false
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def oauth_user?
    authentications.exists?
  end

  def age
    return nil unless date_of_birth
    ((Date.today - date_of_birth) / 365.25).floor
  end

  def generate_password_reset_token!
    password_reset_tokens.create!
  end

  # Friendships
  def friend?(other_user)
    friends.include?(other_user)
  end

  def friend_request_pending_with?(other_user)
    Friendship.exists?(user_id: id, friend_id: other_user.id, status: 'pending') ||
      Friendship.exists?(user_id: other_user.id, friend_id: id, status: 'pending')
  end

  # Messaging
  def unread_messages_from(user)
    received_messages.where(sender: user, read: false).count
  end

  def online?
    updated_at > 5.minutes.ago
  end

  # MFA
  def mfa_enabled?
    mfa_credential&.enabled? || false
  end

  def verify_mfa_code(code)
    mfa_enabled? && mfa_credential.verify_code(code)
  end

  def verify_backup_code(code)
    backup_codes.where(used: false).each do |backup_code|
      return backup_code.mark_as_used! if backup_code.verify(code)
    end
    false
  end

  # ========================================
  # SECURITY: ACCOUNT LOCKOUT
  # ========================================
  def locked?
    locked_at.present? && locked_at > LOCKOUT_DURATION.ago
  end

  def increment_failed_attempts!
    self.failed_login_attempts ||= 0
    self.failed_login_attempts += 1
    self.locked_at = Time.current if failed_login_attempts >= MAX_FAILED_ATTEMPTS
    save(validate: false)
  end

  def reset_failed_attempts!
    update_columns(failed_login_attempts: 0, locked_at: nil)
  end

  # ========================================
  # PRIVATE
  # ========================================
  private

  def password_db
    read_attribute(:password)
  end

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def hash_password
    cost = Rails.env.test? ? 4 : 12
    write_attribute(:password, BCrypt::Password.create(@password, cost: cost))
    @password = nil
  end

  def password_required?
    return false if skip_password_validation
    new_record? || @password.present?
  end

  def password_complexity
    return if @password.blank?

    errors.add :password, 'must be at least 8 characters' if @password.length < 8
    errors.add :password, 'must include an uppercase letter' unless @password.match?(/[A-Z]/)
    errors.add :password, 'must include a lowercase letter' unless @password.match?(/[a-z]/)
    errors.add :password, 'must include a number' unless @password.match?(/[0-9]/)
    errors.add :password, 'must include a special character' unless @password.match?(/[@$!%*?&]/)
  end
end