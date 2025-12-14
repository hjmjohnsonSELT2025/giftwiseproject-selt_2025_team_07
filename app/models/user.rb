class User < ApplicationRecord

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy

  has_many :recipients, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :event_recipients, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy
  has_many :ai_gift_suggestions, dependent: :destroy
  has_one :mfa_credential, dependent: :destroy
  has_many :backup_codes, dependent: :destroy

  # Collaboration relationships
  has_many :collaborators, class_name: "Collaborator", dependent: :destroy
  has_many :collaborating_events, through: :collaborators, source: :event
  has_many :wishlists, dependent: :destroy

  # Friendships
  has_many :friendships, dependent: :destroy
  has_many :friends,
           -> { where(friendships: { status: "accepted" }) },
           through: :friendships,
           source: :friend


  # Incoming collab invites (where user is invited)
  has_many :pending_collaboration_requests,
           -> { pending },
           class_name: "Collaborator",
           foreign_key: :user_id


  has_many :received_friendships,
           class_name: 'Friendship',
           foreign_key: 'friend_id',
           dependent: :destroy

  has_many :pending_friend_requests, -> { pending },
           class_name: 'Friendship', foreign_key: 'friend_id'

  has_many :sent_friend_requests, -> { pending },
           class_name: 'Friendship', foreign_key: 'user_id'

  # Messages
  has_many :sent_messages, class_name: 'Message',
           foreign_key: 'sender_id', dependent: :destroy

  has_many :received_messages, class_name: 'Message',
           foreign_key: 'receiver_id', dependent: :destroy

  # Collaboration relationships
  has_many :collaborators, class_name: "Collaborator", dependent: :destroy
  has_many :collaborating_events, through: :collaborators, source: :event
  has_many :wishlists, dependent: :destroy

  # Friendships
  has_many :friendships, dependent: :destroy
  has_many :friends,
           -> { where(friendships: { status: "accepted" }) },
           through: :friendships,
           source: :friend


  # Incoming collab invites (where user is invited)
  has_many :pending_collaboration_requests,
           -> { pending },
           class_name: "Collaborator",
           foreign_key: :user_id


  has_many :received_friendships,
           class_name: 'Friendship',
           foreign_key: 'friend_id',
           dependent: :destroy

  has_many :pending_friend_requests, -> { pending },
           class_name: 'Friendship', foreign_key: 'friend_id'

  has_many :sent_friend_requests, -> { pending },
           class_name: 'Friendship', foreign_key: 'user_id'

  # Messages
  has_many :sent_messages, class_name: 'Message',
           foreign_key: 'sender_id', dependent: :destroy

  has_many :received_messages, class_name: 'Message',
           foreign_key: 'receiver_id', dependent: :destroy

  attr_accessor :password_confirmation
  attr_reader :password
  attr_accessor :skip_password_validation

  VALID_PHONE_REGEX = /\A(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}\z/
  VALID_GENDERS = ['Male', 'Female', 'Prefer not to say', 'Other']

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, confirmation: true, if: -> { password.present? }
  validates :phone_number, format: { with: VALID_PHONE_REGEX, message: 'is not a valid phone number' }, allow_blank: true
  validates :gender, inclusion: { in: VALID_GENDERS, message: '%{value} is not a valid gender' }, allow_blank: true
  validates :date_of_birth, comparison: { less_than: Date.today, message: 'must be in the past' }, allow_blank: true

  validate :password_complexity, if: :password_required?

  before_save :downcase_email
  before_save :hash_password, if: -> { @password.present? }

  def self.from_omniauth(auth)
    return nil unless auth&.info&.email

    email = auth.info.email.downcase
    user = User.find_by(email: email)

    if user
      auth_record = user.authentications.find_or_initialize_by(
        provider: auth.provider,
        uid: auth.uid
      )

      if auth_record.new_record?
        auth_record.email = auth.info.email
        auth_record.name = auth.info.name
        auth_record.save!
      end
    else
      user = User.new(
        name: auth.info.name,
        email: email
      )
      user.skip_password_validation = true
      user.save!

      user.authentications.create!(
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email,
        name: auth.info.name
      )
    end

    user
  end

  def password=(new_password)
    @password = new_password
  end

  def authenticate(password_attempt)
    return false if password_db.blank?
    BCrypt::Password.new(password_db) == password_attempt ? self : false
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def has_password?
    read_attribute(:password).present?
  end

  def password_login?
    read_attribute(:password).present?
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
  def friend?(other_user)
    friends.include?(other_user)
  end

  def friend_request_pending_with?(other_user)
    Friendship.exists?(user_id: id, friend_id: other_user.id, status: 'pending') ||
      Friendship.exists?(user_id: other_user.id, friend_id: id, status: 'pending')
  end

  def unread_messages_from(user)
    received_messages.where(sender: user, read: false).count
  end

  def online?
    updated_at > 5.minutes.ago
  end

  def mfa_enabled?
    mfa_credential&.enabled? || false
  end

  def verify_mfa_code(code)
    return false unless mfa_enabled?
    mfa_credential.verify_code(code)
  end

  def verify_backup_code(code)
    backup_codes.where(used: false).each do |backup_code|
      if backup_code.verify(code)
        backup_code.mark_as_used!
        return true
      end
    end
    false
  end

  private

  def password_db
    read_attribute(:password)
  end

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def hash_password
    write_attribute(:password, BCrypt::Password.create(@password))
    @password = nil
  end

  def password_required?
    return false if skip_password_validation
    new_record? || @password.present?
  end

  def password_complexity
    return if @password.blank?

    errors.add :password, 'is too short (minimum is 8 characters)' if @password.length < 8
    errors.add :password, 'must contain at least one uppercase letter' unless @password.match(/[A-Z]/)
    errors.add :password, 'must contain at least one lowercase letter' unless @password.match(/[a-z]/)
    errors.add :password, 'must contain at least one number' unless @password.match(/[0-9]/)
    errors.add :password, 'must contain at least one special character' unless @password.match(/[@$!%*?&]/)
  end
end