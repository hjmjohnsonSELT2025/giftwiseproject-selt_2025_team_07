# features/step_definitions/ai_library_steps.rb

def find_or_create_user!(email, name:, password: "Password1!")
  User.find_or_create_by!(email: email) do |u|
    u.name = name
    u.password = password
    u.password_confirmation = password if u.respond_to?(:password_confirmation=)
  end
end

def create_collaboration_link!(event:, user:)
  # Include your real join model
  join_models = %w[
    Collaborator EventCollaborator Collaboration EventCollaboration SharedEvent EventShare EventSharing
  ]

  join_models.each do |klass_name|
    next unless Object.const_defined?(klass_name)
    klass = Object.const_get(klass_name)

    cols = klass.column_names rescue []

    attrs = {}
    attrs[:event] = event if cols.include?("event_id") || (klass.reflect_on_association(:event) rescue false)

    if cols.include?("user_id") || (klass.reflect_on_association(:user) rescue false)
      attrs[:user] = user
    elsif cols.include?("collaborator_id")
      attrs[:collaborator_id] = user.id
    end

    # Make it "accepted" so Event.accessible_to/current scopes pick it up
    if cols.include?("accepted")
      attrs[:accepted] = true
    end

    if cols.include?("status")
      attrs[:status] =
        if klass.const_defined?(:STATUS_ACCEPTED)
          klass::STATUS_ACCEPTED
        else
          "accepted"
        end
    end

    if cols.include?("state")
      attrs[:state] = "accepted"
    end

    if cols.include?("role")
      attrs[:role] =
        if klass.const_defined?(:ROLE_CO_PLANNER)
          klass::ROLE_CO_PLANNER
        else
          "co_planner"
        end
    end

    # Only create if we have the required keys
    if attrs[:event].present? && (attrs[:user].present? || attrs[:collaborator_id].present?)
      klass.create!(attrs)
      return true
    end
  end

  raise "No collaboration join model found. Check your app models and update create_collaboration_link!."
end


def create_event_recipient!(event:, recipient:, user:)
  # Your app seems to use EventRecipient with user/event/recipient in some places
  if defined?(EventRecipient)
    cols = EventRecipient.column_names rescue []
    attrs = { event: event, recipient: recipient }
    attrs[:user] = user if cols.include?("user_id")
    return EventRecipient.create!(attrs)
  end

  nil
end

Given("there is an owned event with AI ideas for {string}") do |email|
  owner = find_or_create_user!(email, name: "Owner User")

  event = Event.create!(
    event_name: "Owned Event",
    event_date: Date.today + 5.days,
    user: owner
  )

  recipient = Recipient.create!(
    user: owner,
    name: "Owned Recipient",
    email: "owned_recipient@example.com",
    relationship: "Friend",
    gender: "Male"
  )

  er = create_event_recipient!(event: event, recipient: recipient, user: owner)

  AiGiftSuggestion.create!(
    user: owner,
    event: event,
    recipient: recipient,
    event_recipient: er,
    title: "Book Subscription",
    category: "Books",
    estimated_price: "$10-$20"
  )
end

When("I visit the AI Gift Library page") do
  visit ai_gift_library_path
end

Then("the category dropdown should include {string}") do |category|
  # In your view, the select name is "category" (Rails generates id="category")
  expect(page).to have_select("category", with_options: [category])
end

Then("the category dropdown should not include {string}") do |category|
  expect(page).not_to have_select("category", with_options: [category])
end

Given("there is a collaboration event accessible to {string} with AI ideas from {string}") do |owner_email, other_email|
  owner = find_or_create_user!(owner_email, name: "Owner User")
  other = find_or_create_user!(other_email, name: "Other User")

  collab_event = Event.create!(
    user: other,
    event_name: "Collab Event",
    event_date: Date.today + 10.days
  )

  # This is the KEY for Collab scope to work:
  create_collaboration_link!(event: collab_event, user: owner)

  recipient = Recipient.create!(
    user: other,
    name: "Alex",
    email: "alex@example.com",
    relationship: "Friend",
    gender: "Male"
  )

  er = create_event_recipient!(event: collab_event, recipient: recipient, user: other)

  AiGiftSuggestion.create!(
    user: other,                 # important: who generated it
    event: collab_event,
    recipient: recipient,
    event_recipient: er,         # if your model validates presence
    title: "Smartwatch",
    category: "Tech",
    estimated_price: "$50-$100"
  )
end
