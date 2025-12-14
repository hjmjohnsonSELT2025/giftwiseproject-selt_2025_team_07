class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  STATUSES = %w[placed delivered cancelled].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :newest_first, -> { order(created_at: :desc) }
end
