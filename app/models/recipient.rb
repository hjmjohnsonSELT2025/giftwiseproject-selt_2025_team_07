class Recipient < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :relationship, inclusion: { in: %w[Mother Father Brother Sister Friend Other] }
end
