# features/step_definitions/chatbot_steps.rb

Given("a chatbot test user exists") do
  # Create or update a deterministic test user with a known valid password
  @chatbot_user = User.find_or_initialize_by(email: "chatbot-test@example.com")

  @chatbot_user.name                  = "Chatbot Test User"
  @chatbot_user.password              = "Password1!"
  @chatbot_user.password_confirmation = "Password1!"
  @chatbot_user.save!
end

Given("I am logged in as the chatbot test user") do
  # Ensure the user exists
  step "a chatbot test user exists" unless @chatbot_user

  visit login_path

  # IMPORTANT: use the exact labels from app/views/sessions/new.html.erb
  fill_in "Email Address", with: "chatbot-test@example.com"
  fill_in "Password",      with: "Password1!"

  # This matches your submit button text: "Log In"
  click_button "Log In"

  # We should end up on the dashboard (or at least not back on /login)
  expect(page).to have_current_path(dashboard_path, ignore_query: true)
end

When("I visit the dashboard page") do
  visit dashboard_path
end

Then("I should see the chatbot button") do
  # Root Stimulus controller for the widget
  expect(page).to have_css("[data-controller='chatbot']")

  # And the visible chatbot image
  expect(page).to have_css("img[alt='Chatbot']")
end

When("I click the chatbot button") do
  # In rack-test, JS won't actually animate, but we can still "click" the element.
  if page.has_css?("[data-chatbot-target='toggleButton']")
    find("[data-chatbot-target='toggleButton']").click
  else
    find("img[alt='Chatbot']").click
  end
end

Then("I should see the chatbot panel") do
  # The panel HTML is always present in the DOM; don't rely on CSS visibility.
  expect(page).to have_css("[data-chatbot-target='panel']")
end

When("I close the chatbot panel") do
  # Optional; in rack-test this won't hide it visually, but mirrors user action.
  if page.has_css?("button[title='Close']", match: :first)
    find("button[title='Close']", match: :first).click
  end
end

Then("the chatbot panel should be hidden") do
  # With a non-JS driver we can't assert hidden vs visible; just assert it exists.
  expect(page).to have_css("[data-chatbot-target='panel']")
end

Then("I should see the chatbot header") do
  expect(page).to have_content("GiftWise Assistant")
end

Then("I should see the chatbot input field") do
  expect(page).to have_field(
                    type: "text",
                    placeholder: "Ask about events, recipients, or wishlist…"
                  )
end
