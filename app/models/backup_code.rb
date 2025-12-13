class BackupCode < ApplicationRecord
  belongs_to :user

  validates :code_digest, presence: true

  def self.generate_codes_for_user(user)
    codes = []
    10.times do
      code = SecureRandom.alphanumeric(8).upcase
      codes << code
      user.backup_codes.create!(code_digest: BCrypt::Password.create(code))
    end
    codes
  end

  def verify(code)
    return false if used?

    BCrypt::Password.new(code_digest) == code
  end

  def mark_as_used!
    update!(used: true, used_at: Time.current)
  end
end