Given("a user exists with email {string} and password {string}") do |email, password|
  @user = User.create!(
    name: "Test User",
    email: email,
    password: password
  )
end

Given("that user has the following events:") do |table|
  table.hashes.each do |row|
    attrs = {
      user: @user,
      event_name: row["event_name"],
      event_date: Date.parse(row["event_date"]),
      budget: row["budget"],
      location: row["location"]
    }

    event = Event.new(attrs)
    event.save!(validate: false) # allow past date for tests
  end
end

Given("I am logged in as {string} with password {string}") do |email, password|
  visit "/login"
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_button "Log In"
end

When("I visit the dashboard") do
  visit "/dashboard"
end

Then("I should see {string} within the upcoming events section") do |event_name|
  within("section", text: "Upcoming Events") do
    expect(page).to have_content(event_name)
  end
end

Then("I should not see {string} within the upcoming events section") do |event_name|
  within("section", text: "Upcoming Events") do
    expect(page).not_to have_content(event_name)
  end
end

When("I click on the event {string} in the upcoming events section") do |event_name|
  event = @user.events.find_by!(event_name: event_name)
  visit event_path(event)end

Then("I should be on the event details page for {string}") do |event_name|
  expect(page).to have_current_path(/\/events\/\d+/)
  expect(page).to have_content(event_name)
end


Then("I should be on the events index page") do
  expect(page).to have_current_path("/events")
  expect(page).to have_content("All Events")
end

Given("I am on the events index page") do
  visit "/events"
end

When("I click on the event row for {string}") do |event_name|
  click_link event_name, match: :first
end
