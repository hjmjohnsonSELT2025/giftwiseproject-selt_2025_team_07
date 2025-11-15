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

When("I submit the recipient form") do
  # Try multiple possible button texts
  begin
    click_button "Save Recipient"
  rescue Capybara::ElementNotFound
    begin
      click_button "Create Recipient"
    rescue Capybara::ElementNotFound
      click_button "Submit"
    end
  end
end

Then("I should be redirected to the dashboard") do
  expect(current_path).to eq(dashboard_path)
end

Given("a recipient named {string} exists") do |name|
  @recipient = @user.recipients.create!(name: name)
end

When("I edit the recipient {string}") do |name|
  rec = Recipient.find_by(name: name)
  visit edit_recipient_path(rec)
end

When("I change the name to {string}") do |new_name|
  fill_in "Name", with: new_name
end

When("I delete the recipient {string}") do |name|
  rec = Recipient.find_by(name: name)
  visit recipients_path
  # Try multiple possible selectors
  begin
    within("tr[data-id='#{rec.id}']") do
      click_button "Remove"
    end
  rescue Capybara::ElementNotFound
    begin
      within("#recipient_#{rec.id}") do
        click_link "Delete"
      end
    rescue Capybara::ElementNotFound
      click_link "Delete", match: :first
    end
  end
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end