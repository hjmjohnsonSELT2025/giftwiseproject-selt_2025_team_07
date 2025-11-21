FactoryBot.define do
  factory :recipient do
    association :user
    name { "Sam" }
    relationship { "Friend" }
  end
end
