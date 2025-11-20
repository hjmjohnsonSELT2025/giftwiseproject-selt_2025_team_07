FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Test User #{n}" }
    sequence(:email) { |n| "testuser#{n}@example.com" }
    password { 'Password1!' }
    password_confirmation { 'Password1!' }

    trait :without_name do
      name { nil }
    end

    trait :with_reset_token do
      after(:create) do |user|
        create(:password_reset_token, user: user)
      end
    end
  end
end
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password@123" }
  end
end
