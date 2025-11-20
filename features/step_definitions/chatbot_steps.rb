# # features/step_definitions/chatbot_steps.rb
# Given("a chatbot test user exists") do
#   @chatbot_user ||= User.find_or_create_by!(email: "chatbot-test@example.com") do |u|
#     u.name  = "Chatbot Test User"
#     # must satisfy your password regex: 8+ chars, upper, lower, digit, special
#     u.password              = "Password1!"
#     u.password_confirmation = "Password1!"
#   end
# end
#
# Given("I am logged in as the chatbot test user") do
#   visit login_path
#
#   # Adjust the field names if your form uses different labels/placeholders
#   fill_in "Email",    with: "chatbot-test@example.com"
#   fill_in "Password", with: "Password1!"
#
#   # Click the first submit button regardless of its text ("Log in", "Login", etc.)
#   find("input[type='submit'],button[type='submit']", match: :first).click
# end
#
# When("I visit the dashboard page") do
#   visit dashboard_path
# end
#
# Then("I should see the chatbot button") do
#   # We know your widget uses <img alt="Chatbot"> inside the floating button
#   expect(page).to have_css("img[alt='Chatbot']")
# end
#
# When("I click the chatbot button") do
#   find("img[alt='Chatbot']").click
# end
#
# Then("I should see the chatbot panel") do
#   # Panel is the div with data-chatbot-target="panel"
#   expect(page).to have_css("[data-chatbot-target='panel']", visible: :visible)
# end
#
# When("I close the chatbot panel") do
#   # The header close button has title="Close"
#   find("button[title='Close']", match: :first).click
# end
#
# Then("the chatbot panel should be hidden") do
#   expect(page).to have_css("[data-chatbot-target='panel']", visible: :hidden)
# end



# features/step_definitions/chatbot_steps.rb
Given("a chatbot test user exists") do
  @chatbot_user ||= User.find_or_create_by!(email: "chatbot-test@example.com") do |u|
    u.name  = "Chatbot Test User"
    u.password              = "Password1!"
    u.password_confirmation = "Password1!"
  end
end

Given("I am logged in as the chatbot test user") do
  visit login_path

  fill_in "Email",    with: "chatbot-test@example.com"
  fill_in "Password", with: "Password1!"

  # works whether it's <input type="submit"> or <button type="submit">
  find("input[type='submit'],button[type='submit']", match: :first).click
end

When("I visit the dashboard page") do
  visit dashboard_path
end

Then("I should see the chatbot button") do
  expect(page).to have_css("img[alt='Chatbot']")
end

When("I click the chatbot button") do
  find("img[alt='Chatbot']").click
end

Then("I should see the chatbot panel") do
  expect(page).to have_css("[data-chatbot-target='panel']", visible: :visible)
end

When("I close the chatbot panel") do
  find("button[title='Close']", match: :first).click
end

Then("the chatbot panel should be hidden") do
  expect(page).to have_css("[data-chatbot-target='panel']", visible: :hidden)
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
