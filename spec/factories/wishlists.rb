FactoryBot.define do
  factory :wishlist do
    association :user
    association :recipient

    # Keep your legacy fields (fine)
    item_name { "Test Item" }
    notes     { "Test notes" }
    priority  { 1 }

    # New association for AI wishlist saves
    association :ai_gift_suggestion
  end
end
