# features/step_definitions/wishlist_steps.rb

def ensure_user!(email)
  User.find_or_create_by!(email: email) do |u|
    u.name = "Test User"
    u.password = "Password1!"
    u.password_confirmation = "Password1!" if u.respond_to?(:password_confirmation=)
  end
end

def create_event_recipient!(event:, recipient:, user:)
  return nil unless defined?(EventRecipient)
  cols = EventRecipient.column_names rescue []
  attrs = { event: event, recipient: recipient }
  attrs[:user] = user if cols.include?("user_id")
  EventRecipient.create!(attrs)
end

Given("I have a wishlist idea titled {string} for recipient {string} and event {string}") do |title, recipient_name, event_name|
  user = ensure_user!("test@example.com")

  event = Event.create!(
    user: user,
    event_name: event_name,
    event_date: Date.today + 7.days
  )

  recipient = Recipient.create!(
    user: user,
    name: recipient_name,
    email: "mom@example.com",
    relationship: "Family",
    gender: "Female"
  )

  er = create_event_recipient!(event: event, recipient: recipient, user: user)

  idea = AiGiftSuggestion.create!(
    user: user,
    event: event,
    recipient: recipient,
    event_recipient: er,
    title: title,
    category: "General",
    estimated_price: "$10-$20"
  )

  Wishlist.create!(user: user, recipient: recipient, ai_gift_suggestion: idea)
end

Given("I have no wishlist items") do
  user = ensure_user!("test@example.com")
  Wishlist.where(user: user).delete_all
end

When("I visit the wishlist page") do
  visit wishlists_path
end

Then("I should see {string} in my wishlist") do |text|
  expect(page).to have_content(text)
end

Then("I should see the empty wishlist message") do
  expect(page).to have_content("Your wishlist is empty.")
  expect(page).to have_content("Browse AI gift ideas for an event and tap the heart icon to save items here.")
end
