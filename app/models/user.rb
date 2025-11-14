class User < ApplicationRecord
  has_many :recipients, dependent: :destroy
  has_many :events, dependent: :destroy
end
