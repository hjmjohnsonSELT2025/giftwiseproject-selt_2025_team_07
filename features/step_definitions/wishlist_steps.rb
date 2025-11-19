# features/step_definitions/wishlist_steps.rb

Given("I have a wishlist idea titled {string} for recipient {string} and event {string}") do |title, recipient_name, event_name|
  # Reuse the test user created in the Background step
  user = User.find_by!(email: "test@example.com")

  event = user.events.create!(
    event_name: event_name,
    event_date: Date.today + 7.days,
    budget: 100
  )

  recipient = user.recipients.create!(
    name: recipient_name,
    relationship: "Family",
    age: 40
  )

  event_recipient = EventRecipient.create!(
    user: user,
    event: event,
    recipient: recipient
  )

  AiGiftSuggestion.create!(
    user: user,
    event: event,
    recipient: recipient,
    event_recipient: event_recipient,
    title: title,
    description: "A very cozy and thoughtful gift.",
    saved_to_wishlist: true
  )
end

Given("I have no wishlist items") do
  user = User.find_by!(email: "test@example.com")
  AiGiftSuggestion.where(user: user).delete_all
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
