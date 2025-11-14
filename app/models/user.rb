class User < ApplicationRecord
  has_many :recipients, dependent: :destroy
  has_many :events, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :age, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  before_save :downcase_email

  def authenticate(password_attempt)
    return false if password.blank?
    password == password_attempt ? self : false
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end