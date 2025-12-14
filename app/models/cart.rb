class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy

  def self.for(user)
    find_or_create_by!(user_id: user.id)
  end
end
