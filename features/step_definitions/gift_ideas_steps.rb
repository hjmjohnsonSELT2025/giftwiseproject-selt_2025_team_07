Given("a recipient with an event exists") do
  # User for these scenarios
  @user = User.create!(
    name: "John Doe",
    email: "john_gift_ideas@example.com",
    password: "Password@123",
    password_confirmation: "Password@123"
  )

  # Recipient belongs to user
  @recipient = Recipient.create!(
    name: "Sam",
    email: "sam@example.com",
    relationship: "Friend",
    user: @user
  )

  # Event belongs to user
  @event = Event.create!(
    event_name: "Birthday",
    event_date: Date.tomorrow,
    user: @user
  )

  # Link event + recipient
  EventRecipient.create!(
    user: @user,
    event: @event,
    recipient: @recipient
  )

  # Log in
  visit login_path
  fill_in "Email", with: @user.email      # change to "Email Address" if that’s your label
  fill_in "Password", with: "Password@123"
  click_button "Log In"
end

Given("a recipient without an event exists") do
  @user = User.create!(
    name: "John No Event",
    email: "john_no_event@example.com",
    password: "Password@123",
    password_confirmation: "Password@123"
  )

  @recipient = Recipient.create!(
    name: "NoEventRecipient",
    email: "noevent@example.com",
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
  # This assumes there is a visible button or link with text "Gift Idea"
  click_link_or_button "Gift Idea"
end

When("I fill in the gift idea form correctly") do
  # Do NOT assume a turbo-frame; work on the whole page.
  # Try a few possible label/ID variations so we don't depend on exact wording.

  # ---- Title / main idea field ----
  title_locators = [
    "Gift Idea", "Gift idea",
    "Gift Name", "Gift name",
    "Title", "Idea",
    "gift_idea_title", "gift_idea_idea"
  ]

  title_filled = false
  title_locators.each do |locator|
    if page.has_field?(locator, disabled: false)
      fill_in locator, with: "Laptop"
      title_filled = true
      break
    end
  end

  raise "Could not find a title field for the gift idea form. Adjust step to match your label." unless title_filled

  # ---- Description field ----
  desc_locators = [
    "Description", "Notes",
    "gift_idea_description"
  ]

  desc_locators.each do |locator|
    if page.has_field?(locator, disabled: false)
      fill_in locator, with: "15 inch, 16GB RAM"
      break
    end
  end

  # ---- Price / Estimated price field ----
  price_locators = [
    "Estimated Price", "Estimated price",
    "Price",
    "gift_idea_estimated_price", "gift_idea_price"
  ]

  price_locators.each do |locator|
    if page.has_field?(locator, disabled: false)
      fill_in locator, with: "999.99"
      break
    end
  end

  # ---- Link / Purchase link field ----
  link_locators = [
    "Link", "URL",
    "Purchase link", "Purchase Link",
    "gift_idea_link"
  ]

  link_locators.each do |locator|
    if page.has_field?(locator, disabled: false)
      fill_in locator, with: "https://example.com/laptop"
      break
    end
  end
end

When('I press {string}') do |text|
  click_on text   # works for both buttons and links
end

# ================================
# THENs
# ================================

Then("I should be on the recipient page") do
  expect(page).to have_current_path(recipient_path(@recipient), ignore_query: true)
end

Then("I should be on the recipients page") do
  expect(page).to have_current_path(recipients_path, ignore_query: true)
end

Then("I should see the new gift idea") do
  # We filled "Laptop" as the idea text
  expect(page).to have_content("Laptop")
end

Then("the Gift Idea button should be disabled") do
  # Works if you render it as a disabled <button>
  expect(page).to have_selector("button[disabled]", text: "Gift Idea")
end
