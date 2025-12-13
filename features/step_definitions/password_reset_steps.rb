#features/step_definitions/password_reset_steps.rb
Given('the following user exists:') do |table|
  table.hashes.each do |row|
    User.create!(
      name: row['name'],
      email: row['email'],
      password: row['password'],
      password_confirmation: row['password']
    )
  end
end

Given('I am on the forgot password page') do
  visit forgot_password_path
end

Then('I should be on the forgot password page') do
  expect(current_path).to eq(forgot_password_path)
end

Given('a password reset token exists for {string}') do |email|
  user = User.find_by(email: email)
  @token = user.generate_password_reset_token!
end

Given('an expired password reset token exists for {string}') do |email|
  user = User.find_by(email: email)
  @token = PasswordResetToken.create!(
    user: user,
    token: SecureRandom.urlsafe_base64(32),
    expires_at: 2.hours.ago,
    used: false
  )
end

Given('a used password reset token exists for {string}') do |email|
  user = User.find_by(email: email)
  @token = PasswordResetToken.create!(
    user: user,
    token: SecureRandom.urlsafe_base64(32),
    expires_at: 1.hour.from_now,
    used: true
  )
end

Given('a password reset token was created {int} minutes ago for {string}') do |minutes, email|
  user = User.find_by(email: email)
  @token = PasswordResetToken.create!(
    user: user,
    token: SecureRandom.urlsafe_base64(32),
    expires_at: (minutes.minutes.ago + 1.hour),
    used: false,
    created_at: minutes.minutes.ago
  )
end

When('I visit the password reset link') do
  visit reset_password_path(token: @token.token)
end

When('I visit an invalid password reset link') do
  visit reset_password_path(token: 'invalid_token_xyz')
end

When('I visit the same password reset link again') do
  visit reset_password_path(token: @token.token)
end

Then('a password reset email should be sent to {string}') do |email|
  user = User.find_by(email: email.downcase)
  mail = ActionMailer::Base.deliveries.find { |m| m.to.include?(user.email) }
  expect(mail).not_to be_nil
end

Then('no password reset email should be sent') do
  expect(ActionMailer::Base.deliveries.count).to eq(0)
end

Then('the email should contain a password reset link') do
  mail = ActionMailer::Base.deliveries.last
  expect(mail.body.encoded).to match(/reset_password\/[A-Za-z0-9_-]+/)
end

Then('the email should be from {string}') do |from_address|
  mail = ActionMailer::Base.deliveries.last
  expect(mail.from).to include(from_address)
end

Then('{int} password reset emails should be sent to {string}') do |count, email|
  user = User.find_by(email: email.downcase)
  emails = ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
  expect(emails.count).to eq(count)
end

Then('both reset links should work independently') do
  expect(PasswordResetToken.active.count).to eq(2)
end

Then('I should be able to reset my password') do
  expect(page).to have_field('New Password')
  expect(page).to have_field('Confirm New Password')
  expect(page).to have_button('Reset Password')
end

Before do
  ActionMailer::Base.deliveries.clear
end