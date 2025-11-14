Given('I am on the sign up page') do
  visit signup_path
end

Given('I am on the login page') do
  visit login_path
end

Given('a user exists with email {string}') do |email|
  User.create!(
    name: 'Existing User',
    email: email,
    password: 'password123'
  )
end

Given('a user exists with email {string} and password {string} and name {string}') do |email, password, name|
  User.create!(
    name: name,
    email: email,
    password: password
  )
end

Given('I am logged in as {string}') do |email|
  user = User.find_by(email: email)
  visit login_path
  fill_in 'Email Address', with: email
  fill_in 'Password', with: 'password123'
  click_button 'Log In'
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I click {string}') do |button_or_link|
  click_link_or_button button_or_link, match: :first
end

When('I visit the home page') do
  visit root_path
end

Then('I should be on the dashboard page') do
  expect(current_path).to eq(dashboard_path)
end

Then('I should be on the login page') do
  expect(current_path).to eq(login_path)
end

Then('I should be on the sign up page') do
  expect(current_path).to eq(signup_path)
end

Then('I should be on the home page') do
  expect(current_path).to eq(root_path)
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Given('I am on the dashboard page') do
  visit dashboard_path
end