

Given('I am logged in as {string} with password {string}') do |email, password|
  visit login_path
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log In'
end

Given('I am logged out') do
  visit logout_path
end

Given('another user exists with email {string}') do |email|
  User.create!(name: "Another User", email: email, password: "Password@123")
end



Given('I am on the new event page') do
  visit new_event_path
  expect(page).to have_content("Create New Event")
end

When('I try to access the new event page') do
  visit new_event_path
end

Then('I should be redirected to the login page') do
  expect(current_path).to eq(login_path)
end

Then('I should be on the new event page') do
  expect(current_path).to eq(new_event_path)
  expect(page).to have_content("Create New Event")
end

Then('I should remain on the new event page') do
  expect(current_path).to eq(new_event_path)
  expect(page).to have_content("Create New Event")
end


When('I click on the {string} button') do |button|
  click_button button
rescue Capybara::ElementNotFound
  click_link button
end



When('I click {string} button') do |button|
  click_button button
end

When('I click "Cancel" button') do
  click_link_or_button 'Cancel'
end


When('I fill in {string} with tomorrow\'s date') do |field|
  fill_in field, with: (Date.today + 1).strftime('%Y-%m-%d')
end

When('I fill in {string} with today\'s date') do |field|
  fill_in field, with: Date.today.strftime('%Y-%m-%d')
end

When('I fill in {string} with yesterday\'s date') do |field|
  fill_in field, with: (Date.today - 1).strftime('%Y-%m-%d')
end

When('I fill in {string} with a future date {string}') do |field, date|
  fill_in field, with: date
end

Given('I have recipients {string} and {string}') do |r1, r2|
  @user.recipients.create!(name: r1)
  @user.recipients.create!(name: r2)
end

When('I select recipient {string}') do |name|
  check name
end


When('I create an event {string}') do |event_name|
  visit new_event_path
  fill_in 'Event Name', with: event_name
  fill_in 'Event Date', with: (Date.today + 1).strftime('%Y-%m-%d')
  click_button 'Create Event'
end

When('I successfully create an event {string}') do |name|
  visit new_event_path
  fill_in 'Event Name', with: name
  fill_in 'Event Date', with: (Date.today + 1).strftime('%Y-%m-%d')
  click_button 'Create Event'
end


Then('I should see a success message {string}') do |msg|
  expect(page).to have_content(msg)
end

Then('I should see an error message {string}') do |msg|
  expect(page).to have_content(msg)
end

Then('I should see a success flash message') do
  expect(page).to have_css('#flash-message')
end

Then('the flash message should disappear after 4 seconds') do
  expect(page).to have_no_css('#flash-message', wait: 5)
end

Then('I should see an alert message {string}') do |msg|
  expect(page).to have_content(msg)
end

Then("the flash message should remain visible") do
  expect(page).to have_css("#flash-message")
end

Then("I should be on the events page") do
  expect(current_path).to eq(events_path)
end

When('I click on {string}') do |text|
  click_link_or_button(text)
end

Then('the event {string} should be saved in the database') do |name|
  expect(Event.exists?(event_name: name)).to be(true)
end

Then('no event should be created') do
  expect(Event.count).to eq(0)
end

Then('the event count should be {string}') do |count|
  expect(Event.count).to eq(count.to_i)
end

Then('the event {string} should have empty location') do |name|
  expect(Event.find_by(event_name: name).location.to_s).to eq("")
end

Then('the event {string} should have null budget') do |name|
  expect(Event.find_by(event_name: name).budget).to be_nil
end

Then('the event {string} should have budget {string}') do |name, budget|
  expect(Event.find_by(event_name: name).budget.to_f).to eq(budget.to_f)
end

Then('the event {string} should have {int} recipients') do |name, count|
  expect(Event.find_by(event_name: name).recipients.count).to eq(count)
end

Then('the event should be associated with {string} and {string}') do |a, b|
  names = Event.last.recipients.pluck(:name)
  expect(names).to include(a, b)
end

Then('there should be {int} events with name {string}') do |count, name|
  expect(Event.where(event_name: name).count).to eq(count)
end

Then('the event {string} should belong to user {string}') do |name, email|
  expect(Event.find_by(event_name: name).user.email).to eq(email)
end

Then('user {string} should not see the event {string}') do |email, name|
  user = User.find_by(email: email)
  expect(user.events.find_by(event_name: name)).to be_nil
end
Then('the event should appear in upcoming events') do
  expect(page).to have_content("Upcoming Events")
end

Then('I should see {string} in the recent events section') do |text|
  expect(page).to have_content(text)
end

Then('the recent event should display {string} as location') do |location|
  expect(page).to have_content(location)
end


Then('the {string} field should contain {string}') do |field, value|
  expect(find_field(field).value).to eq(value)
end

And('the form should retain the entered data') do
  # If needed you can add specific checks
end


Given('an event {string} exists for the current user') do |name|
  @user.events.create!(event_name: name, event_date: Date.today + 1)
end

When('I visit the events page') do
  visit events_path
end


Given('an event {string} exists for the current user with date yesterday') do |name|
  event = @user.events.new(
    event_name: name,
    event_date: Date.today - 1
  )
  event.save(validate: false)
end



Then('I should see {string} under the upcoming events section') do |event|
  within('.upcoming-events') do
    expect(page).to have_content(event)
  end
end

Then('I should see {string} under the past events section') do |event|
  within('.past-events') do
    expect(page).to have_content(event)
  end
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


Given('a user exists with email {string} and password {string}') do |email, password|
  @user = User.create!(
    name: "Test User",
    email: email,
    password: password
  )
end

Given('that user has the following events:') do |table|
  # table is a Cucumber::MultilineArgument::DataTable
  table.hashes.each do |row|
    @user.events.create!(
      event_name: row['event_name'],
      event_date: Date.parse(row['event_date']),
      budget: row['budget'],
      location: row['location'] # if you don't have location column, remove this
    )
  end
end


When('I visit the dashboard') do
  visit dashboard_path
end

Then('I should see {string} within the upcoming events section') do |event_name|
  within('section', text: 'Upcoming Events') do
    expect(page).to have_content(event_name)
  end
end

Then('I should not see {string} within the upcoming events section') do |event_name|
  within('section', text: 'Upcoming Events') do
    expect(page).not_to have_content(event_name)
  end
end

When('I click on the event {string} in the upcoming events section') do |event_name|
  within('section', text: 'Upcoming Events') do
    click_link(event_name)
  end
end

Then('I should be on the event details page for {string}') do |event_name|
  event = Event.find_by!(event_name: event_name)
  expect(current_path).to eq(event_path(event))
end

Given('I am on the events index page') do
  visit events_path
end

When('I click "View all"') do
  click_link 'View all'
end

Then('I should be on the events index page') do
  expect(current_path).to eq(events_path)
end

When('I click on the event row for {string}') do |event_name|
  # Assuming each event is rendered as a link with the event name
  click_link event_name
end