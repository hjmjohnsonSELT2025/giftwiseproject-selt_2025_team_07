class MfaCredential < ApplicationRecord
  belongs_to :user

  validates :secret_key, presence: true
  validates :user_id, uniqueness: true

  def verify_code(code)
    return false unless enabled?

    totp = ROTP::TOTP.new(secret_key)
    totp.verify(code, drift_behind: 30, drift_ahead: 30).present?
  end

  def provisioning_uri(email)
    totp = ROTP::TOTP.new(secret_key, issuer: "GiftWise")
    totp.provisioning_uri(email)
  end
end