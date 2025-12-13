# frozen_string_literal: true

class CollaborationInvite < ApplicationRecord
  belongs_to :event
  belongs_to :inviter, class_name: "User"

  validates :invitee_email, presence: true
  validates :role, presence: true
  validates :status, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :normalize_email
  before_validation :ensure_token, on: :create

  private

  def normalize_email
    self.invitee_email = invitee_email.to_s.strip.downcase
  end

  def ensure_token
    self.token ||= SecureRandom.hex(24)
  end
end
