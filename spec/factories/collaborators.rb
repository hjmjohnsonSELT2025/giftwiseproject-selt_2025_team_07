FactoryBot.define do
  factory :collaborator do
    association :event
    association :user
    role { Collaborator::ROLE_VIEWER }
    status { Collaborator::STATUS_PENDING }

    trait :accepted do
      status { Collaborator::STATUS_ACCEPTED }
    end

    trait :co_planner do
      role { Collaborator::ROLE_CO_PLANNER }
    end

    trait :owner_role do
      role { Collaborator::ROLE_OWNER }
    end
  end
end
