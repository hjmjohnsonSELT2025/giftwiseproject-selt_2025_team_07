# features/step_definitions/gift_ideas_steps.rb

# ================================
# GIVENs
# ================================

Given("a recipient with an event exists") do
  # Create a valid user (matches your password regex)
  @user = User.create!(
    name: "John Doe",
    email: "john_gift_ideas@example.com",
    password: "Password@123",
    password_confirmation: "Password@123"
  )

  # Recipient belongs to user
  @recipient = Recipient.create!(
    name: "Sam",
    relationship: "Friend",
    user: @user
  )

  # Event belongs to user
  @event = Event.create!(
    event_name: "Birthday",
    event_date: Date.tomorrow,
    user: @user
  )

  # EventRecipient belongs to event, recipient AND user
  @event_recipient = EventRecipient.create!(
    user: @user,
    event: @event,
    recipient: @recipient
  )

  # Log in as this user so recipients_path is accessible
  visit login_path
  # Adjust label text if your login form uses "Email Address"
  fill_in "Email", with: @user.email
  fill_in "Password", with: "Password@123"
  click_button "Log In"
end

Given("a recipient without an event exists") do
  # Separate user so this scenario is isolated
  @user = User.create!(
    name: "John No Event",
    email: "john_no_event@example.com",
    password: "Password@123",
    password_confirmation: "Password@123"
  )

  @recipient = Recipient.create!(
    name: "NoEventRecipient",
    relationship: "Friend",
    user: @user
  )

  visit login_path
  fill_in "Email", with: @user.email
  fill_in "Password", with: "Password@123"
  click_button "Log In"
end

# ================================
# WHENs
# ================================

When("I am on the recipients page") do
  visit recipients_path
end

When("I click the Gift Idea button") do
  click_on "Gift Idea"
end

When("I fill in the gift idea form correctly") do
  fill_in "Gift Idea",        with: "Laptop"
  fill_in "Description",      with: "15 inch, 16GB RAM"
  fill_in "Estimated Price",  with: "999.99"
  fill_in "Link",             with: "https://example.com/laptop"
end

When('I press {string}') do |text|
  click_on text   # works for both submit button and Cancel link
end

# ================================
# THENs
# ================================

Then("I should be on the recipient page") do
  # After saving we redirect to recipients index in your controller
  expect(page).to have_current_path(recipient_path(@recipient), ignore_query: true)
end

Then("I should be on the recipients page") do
  expect(page).to have_current_path(recipients_path, ignore_query: true)
end

Then("I should see the new gift idea") do
  expect(page).to have_content("Laptop")
end

Then("the Gift Idea button should be disabled") do
  # We just assert there exists a disabled Gift Idea button
  expect(page).to have_selector("button[disabled]", text: "Gift Idea")
end
