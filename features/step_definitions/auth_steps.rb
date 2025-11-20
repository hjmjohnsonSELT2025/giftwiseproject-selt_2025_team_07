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
    password: 'Password1!123'
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
  fill_in 'Password', with: 'Password1!'
  click_button 'Log In'
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I click {string}') do |button_or_link|
  if button_or_link == "Continue with Google"
    @initiating_google_oauth = true
  else
    click_link_or_button button_or_link, match: :first
  end
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

Then('I should be redirected to the dashboard') do
  expect(current_path).to eq(dashboard_path)
end

Given('I am on the dashboard page') do
  visit dashboard_path
end

When('I select {string} from {string}') do |option, field|
  select option, from: field
end

Given('a Google user exists with email {string} and name {string}') do |email, name|
  user = User.new(name: name, email: email)
  user.skip_password_validation = true
  user.save!
  user.authentications.create!(
    provider: 'google_oauth2',
    uid: Digest::SHA256.hexdigest(email),
    email: email,
    name: name
  )
end

And('Google authentication succeeds with email {string} and name {string}') do |email, name|
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                       provider: 'google_oauth2',
                                                                       uid: Digest::SHA256.hexdigest(email),
                                                                       info: {
                                                                         email: email,
                                                                         name: name
                                                                       }
                                                                     })

  visit '/auth/google_oauth2/callback'
end

When('Google authentication fails') do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
  visit '/auth/google_oauth2/callback'
end

Then('a user should exist with email {string}') do |email|
  expect(User.find_by(email: email)).to be_present
end

Then('the user {string} should have no password') do |email|
  user = User.find_by(email: email)
  expect(user.has_password?).to be_falsey
end

Then('the user {string} should have a Google authentication') do |email|
  user = User.find_by(email: email)
  expect(user.authentications.where(provider: 'google_oauth2')).to exist
end

Given('I am logged in as Google user {string}') do |email|
  user = User.find_by(email: email)
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
     provider: 'google_oauth2',
     uid: user.authentications.first.uid,
     info: {
       email: email,
       name: user.name
     }
   })

  visit '/auth/google_oauth2/callback'
end

When('I visit the change password page') do
  visit edit_password_path
end

Then('the user {string} should have a password') do |email|
  user = User.find_by(email: email)
  expect(user.has_password?).to be_truthy
end

Given('the user {string} has linked their Google account') do |email|
  user = User.find_by(email: email)
  user.authentications.create!(
    provider: 'google_oauth2',
    uid: Digest::SHA256.hexdigest(email),
    email: email,
    name: user.name
  )
end
Given("I am on the signup page") do
  visit signup_path
end
