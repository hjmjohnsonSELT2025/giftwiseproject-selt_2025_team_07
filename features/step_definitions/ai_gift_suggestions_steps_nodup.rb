# features/step_definitions/ai_gift_suggestions_steps_nodup.rb

# ---------- Shared setup ----------

Given("I have an event {string} with a recipient {string}") do |event_name, recipient_name|
  @user = User.find_by!(email: "test@example.com")

  @event = @user.events.create!(
    event_name: event_name,
    event_date: Date.today + 7.days,
    budget: 100
  )

  @recipient = @user.recipients.create!(
    name:         recipient_name,
    relationship: "Friend"
  )

  EventRecipient.create!(
    user:             @user,
    event:            @event,
    recipient:        @recipient,
    budget_allocated: 50
  )
end

Given("AI gift suggestions already exist for {string} on {string}:") do |recipient_name, event_name, table|
  user      = User.find_by!(email: "test@example.com")
  event     = user.events.find_by!(event_name: event_name)
  recipient = user.recipients.find_by!(name: recipient_name)
  event_recipient = EventRecipient.find_by!(user: user, event: event, recipient: recipient)

  table.hashes.each do |row|
    AiGiftSuggestion.create!(
      user:              user,
      event:             event,
      recipient:         recipient,
      event_recipient:   event_recipient,
      round_type:        "initial",
      title:             row["title"],
      description:       row["description"],
      category:          row["category"],
      estimated_price:   row["estimated_price"],
      saved_to_wishlist: row["saved_to_wishlist"].to_s == "true"
    )
  end
end

# ---------- No-duplicate regeneration scenario ----------

When("I go to the AI gift suggestions page for {string}") do |event_name|
  user  = User.find_by!(email: "test@example.com")
  event = user.events.find_by!(event_name: event_name)
  visit event_ai_gift_suggestions_path(event)
end

When('I click "Regenerate ideas" for {string}') do |recipient_name|
  # Find the recipient card by name, same style as other AI steps
  card = all("div.bg-white.rounded-3xl.shadow-sm.border.border-gray-200").find do |node|
    node.has_text?(recipient_name)
  end

  within(card) do
    click_button "Regenerate ideas"
  end
end


Then("I should see {int} AI gift ideas for {string}") do |count, _recipient_name|
  expect(page).to have_css(".ai-gift-card", count: count)
end

# ---------- AI Library scenario ----------

When("I visit the AI gift library") do
  visit ai_gift_library_path
end

When("I filter the AI library by event {string} and recipient {string} and saved only") do |event_name, recipient_name|
  user  = User.find_by!(email: "test@example.com")
  event = user.events.find_by!(event_name: event_name)

  event_label = "#{event.event_name} (#{event.event_date&.strftime('%b %d')})"

  select(event_label, from: "event_id")
  select(recipient_name, from: "recipient_id")

  check("Saved to wishlist only")
  click_button("Apply filters")
end
