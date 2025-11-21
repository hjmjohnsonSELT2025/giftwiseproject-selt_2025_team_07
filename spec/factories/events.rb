FactoryBot.define do
  factory :event do
    association :user
    event_name { "Birthday" }
    event_date { Date.today }
    budget { 100 }
  end
end
