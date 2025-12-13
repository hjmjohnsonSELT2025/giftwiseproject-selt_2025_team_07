FactoryBot.define do
  factory :collaboration_invite do
    event { nil }
    inviter { nil }
    invitee_email { "MyString" }
    role { "MyString" }
    token { "MyString" }
    status { "MyString" }
    sent_at { "2025-12-12 19:48:59" }
    accepted_at { "2025-12-12 19:48:59" }
    expires_at { "2025-12-12 19:48:59" }
  end
end
