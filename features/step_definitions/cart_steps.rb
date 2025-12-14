Given("I am logged in") do
  @user = User.create!(name: "Cuke User", email: "cuke@example.com", password: "Password@1", password_confirmation: "Password@1")

  visit login_path
  fill_in "email", with: @user.email
  fill_in "password", with: "Password@1"
  click_button "Log In"
end

Given("an AI gift suggestion exists") do
  event = Event.create!(user: @user, event_name: "Cuke Event", event_date: Date.today + 5, budget: 100)
  recipient = Recipient.create!(user: @user, name: "Sam", relationship: "Friend")
  event_recipient = EventRecipient.create!(event: event, recipient: recipient)

  @idea = AiGiftSuggestion.create!(
    user: @user,
    event: event,
    recipient: recipient,
    event_recipient: event_recipient,
    title: "Shoes",
    description: "Running shoes",
    category: "Fashion",
    estimated_price: "$70"
  )
end

When("I visit the cart page") do
  visit cart_path
end

When("I add that suggestion to the cart") do
  # Direct POST is easiest for cucumber without depending on a specific button location
  page.driver.post(cart_items_path, { ai_gift_suggestion_id: @idea.id })
  visit cart_path
end

Given("my cart has at least one item") do
  step "an AI gift suggestion exists"
  cart = Cart.for(@user)
  CartItem.create!(cart: cart, ai_gift_suggestion: @idea, event_id: @idea.event_id, recipient_id: @idea.recipient_id, quantity: 1)
end

When("I clear the cart") do
  page.driver.delete(clear_cart_items_path)
  visit cart_path
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end
