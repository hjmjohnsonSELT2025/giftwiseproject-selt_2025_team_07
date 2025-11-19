class User < ApplicationRecord
  has_many :recipients, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :event_recipients, dependent: :destroy
  has_many :authentications, dependent: :destroy

  attr_accessor :password_confirmation
  attr_reader :password

  VALID_PHONE_REGEX = /\A(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}\z/
  VALID_PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}\z/
  VALID_GENDERS = ['Male', 'Female', 'Prefer not to say', 'Other']

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, format: { with: VALID_PASSWORD_REGEX, message: 'must be at least 8 characters and include uppercase, lowercase, number, and special character' }, if: :password_required?
  validates :password, confirmation: true, if: -> { password.present? }
  validates :phone_number, format: { with: VALID_PHONE_REGEX, message: 'is not a valid phone number' }, allow_blank: true
  validates :gender, inclusion: { in: VALID_GENDERS, message: '%{value} is not a valid gender' }, allow_blank: true
  validates :date_of_birth, comparison: { less_than: Date.today, message: 'must be in the past' }, allow_blank: true

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
    password_db.present?
  end

  def oauth_user?
    authentications.exists?
  end

  def age
    return nil unless date_of_birth
    ((Date.today - date_of_birth) / 365.25).floor
  end

  attr_accessor :skip_password_validation

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
end