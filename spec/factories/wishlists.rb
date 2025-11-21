FactoryBot.define do
  factory :wishlist do
    association :user
    association :recipient
    item_name { "Test Item" }
    notes     { "Test notes" }
    priority  { 1 }
  end
end
