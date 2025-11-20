FactoryBot.define do
  factory :recipient do
    association :user
    name { "Sam" }
    relationship { "Friend" }
    user_id { 1 } # adjust if you add a User factory later
  end
end
