FactoryBot.define do
  factory :event do
    association :user

    # Adjust these attribute names if your schema is slightly different.
    # These names are common in your GiftWise app.
    event_name { "Birthday" }
    event_date { Date.today }
  end
end
