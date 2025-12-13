Given('I have MFA enabled') do
  secret = ROTP::Base32.random
  @user.create_mfa_credential!(
    secret_key: secret,
    enabled: true,
    enabled_at: Time.current
  )
  @mfa_secret = secret
end

Given('I have MFA enabled with backup codes') do
  secret = ROTP::Base32.random
  @user.create_mfa_credential!(
    secret_key: secret,
    enabled: true,
    enabled_at: Time.current
  )
  @mfa_secret = secret
  @backup_codes = BackupCode.generate_codes_for_user(@user)
end

Given('I am an OAuth user') do
  @oauth_user = User.create!(
    name: 'OAuth User',
    email: 'oauth@example.com',
    skip_password_validation: true
  )
  @oauth_user.authentications.create!(
    provider: 'google_oauth2',
    uid: '123456789',
    email: 'oauth@example.com',
    name: 'OAuth User'
  )
  @user = @oauth_user
end

Given('I am logged in via OAuth') do
  visit login_path
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                       provider: 'google_oauth2',
                                                                       uid: '123456789',
                                                                       info: {
                                                                         email: 'oauth@example.com',
                                                                         name: 'OAuth User'
                                                                       }
                                                                     })
  visit '/auth/google_oauth2/callback'
end

When('I visit the MFA setup page') do
  visit setup_mfa_path
end

When('I scan the QR code with my authenticator app') do
  @mfa_secret = page.text.match(/([A-Z0-9]{32})/)[1]
end

When('I enter a valid MFA code') do
  @mfa_secret ||= page.text.match(/([A-Z0-9]{32})/)[1]
  totp = ROTP::TOTP.new(@mfa_secret)
  @valid_code = totp.now
  fill_in 'code', with: @valid_code
end

When('I enter an invalid MFA code {string}') do |code|
  fill_in 'code', with: code
end

When('I submit the MFA setup form') do
  click_button 'Enable MFA'
end

When('I submit the MFA setup form without entering a code') do
  click_button 'Enable MFA'
end

When('I attempt to disable MFA') do
  page.driver.submit :delete, disable_mfa_path, {}
end

When('I submit the MFA verification form') do
  click_button 'Verify Code'
end

When('I enter a valid backup code') do
  @used_backup_code = @backup_codes.first
end

When('I enter an invalid backup code {string}') do |code|
  @invalid_backup_code = code
end

When('I submit the backup code verification form') do
  page.driver.submit :post, verify_backup_code_mfa_session_path, { backup_code: @used_backup_code || @invalid_backup_code }
end

When('I enter the same backup code') do
  # Already stored in @used_backup_code
end

When('I login via OAuth') do
  visit login_path
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                       provider: 'google_oauth2',
                                                                       uid: '123456789',
                                                                       info: {
                                                                         email: 'oauth@example.com',
                                                                         name: 'OAuth User'
                                                                       }
                                                                     })
  visit '/auth/google_oauth2/callback'
end

When('my session is cleared') do
  Capybara.reset_sessions!
end

When('I try to verify MFA code') do
  visit new_mfa_session_path
end

Then('I should see a QR code for Google Authenticator') do
  has_qr = page.has_css?('img') || page.has_content?('Scan QR Code')
  expect(has_qr).to be true
end

Then('I should see the secret key') do
  has_secret = page.has_content?('Secret Key') || page.has_content?('Enter Manually')
  expect(has_secret).to be true
  expect(page.text).to match(/[A-Z0-9]{32}/)
end

Then('I should see {int} backup codes') do |count|
  codes = page.text.scan(/\b[A-Z0-9]{8}\b/).uniq
  expect(codes.count).to eq(count)
end

Then('MFA should be enabled for my account') do
  @user.reload
  expect(@user.mfa_enabled?).to be true
end

Then('MFA should not be enabled for my account') do
  @user.reload
  expect(@user.mfa_enabled?).to be false
end

Then('I should not be logged in yet') do
  expect(page.current_path).to match(/mfa_session/)
  expect(page.current_path).not_to eq(dashboard_path)
end

Then('I should be logged in') do
  visit dashboard_path
  expect(page).to have_current_path(dashboard_path)
  expect(page).not_to have_content('You must be logged in')
end

Then('the backup code should be marked as used') do
  used_codes = @user.backup_codes.where(used: true)
  expect(used_codes.count).to be >= 1
end

Then('I should not see MFA verification page') do
  expect(page).not_to have_content('Two-Factor Authentication')
  expect(page).not_to have_content('Enter the code from your authenticator app')
  expect(page.current_path).not_to match(/mfa_session/)
end