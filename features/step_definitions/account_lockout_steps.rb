# features/step_definitions/account_lockout_steps.rb
# MINIMAL VERSION - Only lockout-specific steps (NO duplicates!)

# ========================================
# LOCKOUT-SPECIFIC SETUP STEPS
# ========================================

Given("the user {string} has {int} failed login attempt(s)") do |email, count|
  user = User.find_by!(email: email)
  user.update_columns(failed_login_attempts: count)
end

Given("the user {string} has {int} failed login attempts and is locked") do |email, count|
  user = User.find_by!(email: email)
  user.update_columns(
    failed_login_attempts: count,
    locked_at: Time.current
  )
end

Given("the user {string} was locked {int} minutes ago") do |email, minutes|
  user = User.find_by!(email: email)
  user.update_columns(
    failed_login_attempts: 5,
    locked_at: minutes.minutes.ago
  )
end

Given("a user exists via Google OAuth with email {string}") do |email|
  user = User.new(
    name: "OAuth User",
    email: email
  )
  user.skip_password_validation = true
  user.save!

  user.authentications.create!(
    provider: 'google_oauth2',
    uid: '123456789',
    email: email,
    name: 'OAuth User'
  )
end

# ========================================
# LOCKOUT-SPECIFIC ACTION STEPS
# ========================================

When("I visit the login page") do
  visit login_path
end

When("I visit the forgot password page") do
  visit forgot_password_path
end

When("I attempt to log in {int} times with wrong password for {string}") do |times, email|
  times.times do
    visit login_path
    fill_in 'Email', with: email
    fill_in 'Password', with: 'WrongPassword123!'
    click_button 'Log In'
  end
end

When("I follow the password reset link from email") do
  user = User.last
  token = user.password_reset_tokens.last
  visit "/password_resets/#{token}/edit"
end

# ========================================
# LOCKOUT-SPECIFIC ASSERTION STEPS
# ========================================

Then("the user {string} should have {int} failed login attempt(s)") do |email, count|
  user = User.find_by!(email: email)
  expect(user.failed_login_attempts).to eq(count)
end

Then("the user {string} should be locked") do |email|
  user = User.find_by!(email: email)
  expect(user.locked?).to be true
  expect(user.locked_at).to be_present
end

Then("the user {string} should not be locked") do |email|
  user = User.find_by!(email: email)
  expect(user.locked?).to be false
end

Then("I should not be logged in") do
  expect(page).not_to have_content("Welcome back")
  expect(page).not_to have_link("Log Out")
end

Then("I should not be on the dashboard page") do
  expect(current_path).not_to eq(dashboard_path)
end

