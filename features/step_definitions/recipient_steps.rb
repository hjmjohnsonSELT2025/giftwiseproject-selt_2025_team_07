Given("I am logged in") do
  @user = User.create!(name: "Test User", email: "test@test.com", password: "Password1!")
  visit login_path
  fill_in "Email", with: "test@test.com"
  fill_in "Password", with: "Password1!"
  click_button "Log In"
end


When("I visit the recipients page") do
  visit recipients_path
end

Then("I should see the list of my recipients") do
  expect(page).to have_content("Recipients")
end

When("I visit the new recipient page") do
  visit new_recipient_path
end


When("I edit the recipient {string}") do |name|
  rec = Recipient.find_by(name: name)
  visit edit_recipient_path(rec)
end

When("I delete the recipient {string}") do |name|
  visit recipients_path
  expect(page).to have_content(name)

  # Just click Delete – no JS confirm handling in rack_test driver
  first(:link_or_button, "Remove").click
end



Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end

Given("I am on the new recipient page") do
  visit new_recipient_path
end


When("I submit the updated recipient form") do
  # Try multiple possible button texts
  begin
    click_button "Save Recipient"
  rescue Capybara::ElementNotFound
    begin
      click_button "Update Recipient"
    rescue Capybara::ElementNotFound
      click_button "Submit"
    end
  end
end
