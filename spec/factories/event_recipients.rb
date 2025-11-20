FactoryBot.define do
  factory :event_recipient do
    association :user
    association :recipient
    association :event
  end
end
