# features/step_definitions/gift_given_backlog_steps.rb

Given('a recipient named {string} exists for the current user') do |name|
  # Use the user created in the background step
  user = @user || User.find_by!(email: "john@example.com")

  @recipient = Recipient.create!(
    name:         name,
    email:        "#{name.downcase}@example.com",
    relationship: "Friend",
    user:         user
  )
end

When('I click "Gift Given" for {string}') do |recipient_name|
  # Find the table row that contains this recipient and click its "Gift Given" button
  within(:xpath, "//tr[.//text()[contains(normalize-space(), '#{recipient_name}')]]") do
    click_link_or_button("Gift Given")
  end
end

When("I fill in the gift given form correctly") do
  # If your modal is wrapped in turbo-frame id="modal", you can optionally scope it:
  # within("turbo-frame#modal") do ... end
  fill_in "Gift name",     with: "Perfume"
  fill_in "Event name",    with: "Birthday"
  fill_in "Price",         with: "49.99"
  fill_in "Category",      with: "Fragrance"
  fill_in "Purchase link", with: "https://example.com/perfume"
  fill_in "Given on",      with: Date.today.strftime("%m/%d/%Y")
end

When("I fill in the gift given form with an empty gift name") do
  fill_in "Gift name", with: ""
end

Then("I should be on the recipient page for {string}") do |_name|
  # After Save / Cancel, we stay on the recipients index page
  expect(page).to have_current_path(recipients_path, ignore_query: true)
end



Then("I should see the new gift given in the backlog table") do
  expect(page).to have_content("Perfume")
end

Then("I should not see any new gift given added to the backlog table") do
  expect(page).not_to have_content("Perfume")
end
