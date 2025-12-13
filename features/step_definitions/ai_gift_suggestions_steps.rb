# features/step_definitions/ai_gift_suggestions_steps.rb

Given("I have an upcoming event {string} with a recipient {string}") do |event_name, recipient_name|
  @current_user ||= User.find_by(email: "test@example.com") ||
                    User.create!(name: "Test User", email: "test@example.com", password: "Password1!")

  @event = @current_user.events.create!(
    event_name: event_name,
    event_date: Date.today + 10.days,
    budget: 100
  )

  @recipient = @current_user.recipients.create!(
    name: recipient_name,
    relationship: "Family",
    age: 40
  )

  EventRecipient.create!(
    user: @current_user,
    event: @event,
    recipient: @recipient
  )
end

Given("I have an upcoming event {string} with no recipients") do |event_name|
  @current_user ||= User.find_by(email: "test@example.com") ||
                    User.create!(name: "Test User", email: "test@example.com", password: "Password1!")

  @event_without_recipients = @current_user.events.create!(
    event_name: event_name,
    event_date: Date.today + 5.days,
    budget: 50
  )
end

Then("I should see an enabled {string} button for {string}") do |button_text, event_name|
  # Scope to the Upcoming Events section to avoid other cards
  within("section", text: "Upcoming Events") do
    row = all("div.flex.items-center.justify-between").find { |node| node.has_text?(event_name) }

    within(row) do
      link = find("a", text: button_text)
      expect(link[:class]).not_to include("cursor-not-allowed")
    end
  end
end

Then("I should see a disabled {string} button for {string}") do |button_text, event_name|
  within("section", text: "Upcoming Events") do
    row = all("div.flex.items-center.justify-between").find { |node| node.has_text?(event_name) }

    within(row) do
      button = find("button", text: button_text)
      expect(button[:disabled]).to eq("disabled")
      expect(button[:class]).to include("cursor-not-allowed")
    end
  end
end

When("I click {string} for {string} from the dashboard") do |button_text, event_name|
  visit dashboard_path

  within("section", text: "Upcoming Events") do
    row = all("div.flex.items-center.justify-between").find { |node| node.has_text?(event_name) }

    within(row) do
      click_link button_text
    end
  end
end

When("I click {string} for recipient {string}") do |button_text, recipient_name|
  # On the AI page, find the recipient card and click its button
  card = all("div.bg-white.rounded-3xl.shadow-sm.border.border-gray-200").find do |node|
    node.has_text?(recipient_name)
  end

  within(card) do
    click_button button_text
  end
end

Then("I should be on the AI gift ideas page for {string}") do |event_name|
  expect(page).to have_content("AI Gift Ideas")
  expect(page).to have_content(event_name)
end

Then("I should see at least 1 AI gift idea card for {string}") do |recipient_name|
  card = all("div.bg-white.rounded-3xl.shadow-sm.border.border-gray-200").find do |node|
    node.has_text?(recipient_name)
  end

  within(card) do
    idea_cards = all("div.border.border-gray-100.rounded-2xl")
    expect(idea_cards.size).to be >= 1
  end
end

# ----------------------------
# Support steps for "regen" / existing suggestions
# ----------------------------

Given("AI gift suggestions already exist for {string} on {string}:") do |recipient_name, event_name, table|
  user = User.find_by!(email: "test@example.com")

  event = Event.find_by!(event_name: event_name, user_id: user.id)
  recipient = Recipient.find_by!(name: recipient_name, user_id: user.id)

  # Ensure EventRecipient exists (since your controller uses it)
  er =
    if defined?(EventRecipient)
      cols = EventRecipient.column_names rescue []
      attrs = { event: event, recipient: recipient }
      attrs[:user] = user if cols.include?("user_id")
      EventRecipient.find_or_create_by!(attrs)
    end

  table.hashes.each do |row|
    suggestion = AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: er,
      title: row["title"],
      category: row["category"].presence || "General",
      estimated_price: "$10-$20"
    )

    saved = row["saved_to_wishlist"].to_s.strip.downcase == "true"
    if saved
      # recipient_id is NOT NULL in your DB, so include it.
      Wishlist.find_or_create_by!(
        user_id: user.id,
        ai_gift_suggestion_id: suggestion.id,
        recipient_id: recipient.id
      )
    end
  end
end


When("I go to the AI gift suggestions page for {string}") do |event_name|
  user  = User.find_by!(email: "test@example.com")
  event = user.events.find_by!(event_name: event_name)
  visit event_ai_gift_suggestions_path(event)
end

# This name is intentionally specific (to avoid ambiguous matches with other click steps)
When('I click "Regenerate ideas" for recipient {string}') do |recipient_name|
  card = all("div.bg-white.rounded-3xl.shadow-sm.border.border-gray-200").find do |node|
    node.has_text?(recipient_name)
  end

  within(card) do
    click_button "Regenerate ideas"
  end
end

Then("I should see {int} AI gift ideas for {string}") do |count, recipient_name|
  card = all("div.bg-white.rounded-3xl.shadow-sm.border.border-gray-200").find do |node|
    node.has_text?(recipient_name)
  end

  within(card) do
    # Use the same selector you used in the "at least 1" step
    expect(page).to have_css("div.border.border-gray-100.rounded-2xl", count: count)
  end
end

# Alias for existing step (feature wording mismatch)
Given("I have an event {string} with a recipient {string}") do |event_name, recipient_name|
  step %{I have an upcoming event "#{event_name}" with a recipient "#{recipient_name}"}
end

# Simpler regenerate click (feature wording)
When('I click "Regenerate ideas" for {string}') do |recipient_name|
  card = all("div.bg-white.rounded-3xl").find { |c| c.has_text?(recipient_name) }
  within(card) { click_button "Regenerate ideas" }
end

# Library alias
When("I visit the AI gift library") do
  visit ai_gift_library_path
end

# Filter step (minimal, deterministic)
When("I filter the AI library by event {string} and recipient {string} and saved only") do |event_name, recipient_name|
  # Event filter
  if page.has_select?("Event", wait: 2)
    select event_name, from: "Event"
  elsif page.has_select?("event_id", wait: 2)
    select event_name, from: "event_id"
  elsif page.has_css?("select[name='event_id']", wait: 2)
    find("select[name='event_id']").select(event_name)
  elsif page.has_field?("event", wait: 2)
    fill_in "event", with: event_name
  elsif page.has_field?("event_id", wait: 2)
    fill_in "event_id", with: event_name
  else
    raise "Could not find an Event filter control (select or input) on the AI library page."
  end

  # Recipient filter
  if page.has_select?("Recipient", wait: 2)
    select recipient_name, from: "Recipient"
  elsif page.has_select?("recipient_id", wait: 2)
    select recipient_name, from: "recipient_id"
  elsif page.has_css?("select[name='recipient_id']", wait: 2)
    find("select[name='recipient_id']").select(recipient_name)
  elsif page.has_field?("recipient", wait: 2)
    fill_in "recipient", with: recipient_name
  else
    raise "Could not find a Recipient filter control (select or input) on the AI library page."
  end

  # Saved-only checkbox
  if page.has_unchecked_field?("Saved only", wait: 2) || page.has_field?("Saved only", wait: 2)
    check "Saved only"
  elsif page.has_css?("input[name='saved_only']", wait: 2)
    find("input[name='saved_only']").check
  end

  click_button "Apply filters"
end

