FactoryBot.define do
  factory :ai_gift_suggestion do
    association :user
    association :event
    association :recipient
    association :event_recipient

    round_type { "initial" }
    title { "Smartwatch" }
    description { "Tech gift" }
    category { "Tech" }
    estimated_price { "$100–$200" }
    saved_to_wishlist { false }
  end
end
