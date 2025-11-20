FactoryBot.define do
  factory :gift_idea do
    association :event_recipient
    idea { "Laptop" }
    description { "A nice gift" }
    price_estimate { 999.99 }
    link { "https://example.com" }
  end
end
