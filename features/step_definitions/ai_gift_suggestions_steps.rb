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
    row = all("div.flex.items-center.justify-between").find do |node|
      node.has_text?(event_name)
    end

    within(row) do
      link = find("a", text: button_text)
      expect(link[:class]).not_to include("cursor-not-allowed")
    end
  end
end

Then("I should see a disabled {string} button for {string}") do |button_text, event_name|
  within("section", text: "Upcoming Events") do
    row = all("div.flex.items-center.justify-between").find do |node|
      node.has_text?(event_name)
    end

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
    row = all("div.flex.items-center.justify-between").find do |node|
      node.has_text?(event_name)
    end

    within(row) do
      click_link button_text
    end
  end
end

When("I click {string} for recipient {string}") do |button_text, recipient_name|
  # On the AI page, find the recipient card and click its Generate button
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

  # features/step_definitions/ai_gift_suggestions_steps.rb

  Given("AI gift suggestions already exist for {string} on {string}:") do |recipient_name, event_name, table|
    user = @current_user || User.last # depending on your auth setup

    event = user.events.find_by!(event_name: event_name)
    recipient = user.recipients.find_by!(name: recipient_name)
    event_recipient = EventRecipient.find_by!(user: user, event: event, recipient: recipient)

    table.hashes.each do |row|
      AiGiftSuggestion.create!(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        title: row.fetch("title"),
        description: "Existing suggestion for testing",
        round_type: "initial"
      )
    end
  end

  When("I click {string} for {string}") do |button_text, recipient_name|
    # Assuming you show a regenerate button per recipient on the page
    within(:xpath, "//div[contains(., '#{recipient_name}')]") do
      click_button(button_text)
    end
  end

end

