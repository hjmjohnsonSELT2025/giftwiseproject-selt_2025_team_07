Feature: Multi-Factor Authentication (MFA)
  As a user
  I want to enable multi-factor authentication
  So that my account is more secure

  Background:
    Given I am a registered user with email "user@example.com" and password "Password123!"
    When I login with email "user@example.com" and password "Password123!"

  Scenario: User with password can access MFA setup page
    When I visit the MFA setup page
    Then I should see "Set Up Two-Factor Authentication"
    And I should see a QR code for Google Authenticator
    And I should see the secret key

  Scenario: OAuth user cannot enable MFA without password
    When I logout
    And I am an OAuth user
    And I am logged in via OAuth
    When I visit the MFA setup page
    Then I should be redirected to the profile edit page
    And I should see "You must set a password before enabling MFA"

  Scenario: User successfully enables MFA with valid code
    When I visit the MFA setup page
    And I scan the QR code with my authenticator app
    And I enter a valid MFA code
    And I submit the MFA setup form
    Then I should see "Backup Codes"
    And I should see 10 backup codes
    And MFA should be enabled for my account

  Scenario: User cannot enable MFA with invalid code
    When I visit the MFA setup page
    And I enter an invalid MFA code "000000"
    And I submit the MFA setup form
    Then I should be redirected to the MFA setup page
    And I should see "Invalid code. Please try again."
    And MFA should not be enabled for my account

  Scenario: User cannot enable MFA without entering a code
    When I visit the MFA setup page
    And I submit the MFA setup form without entering a code
    Then I should be redirected to the MFA setup page
    And I should see "Please enter the authentication code"

  Scenario: User cannot access MFA setup when already enabled
    Given I have MFA enabled
    When I visit the MFA setup page
    Then I should be redirected to the profile edit page
    And I should see "MFA is already enabled"

  Scenario: User successfully disables MFA
    Given I have MFA enabled
    When I visit the profile edit page
    And I attempt to disable MFA
    Then I should be redirected to the profile edit page
    And I should see "MFA has been disabled successfully"
    And MFA should not be enabled for my account

  Scenario: User cannot disable MFA when not enabled
    When I visit the profile edit page
    And I attempt to disable MFA
    Then I should be redirected to the profile edit page
    And I should see "MFA is not enabled"

  Scenario: User must verify MFA code during login
    Given I have MFA enabled
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    Then I should see "Two-Factor Authentication"
    And I should not be logged in yet

  Scenario: User successfully logs in with valid MFA code
    Given I have MFA enabled
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    And I enter a valid MFA code
    And I submit the MFA verification form
    Then I should be redirected to the dashboard
    And I should see "Successfully authenticated"
    And I should be logged in

  Scenario: User cannot login with invalid MFA code
    Given I have MFA enabled
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    And I enter an invalid MFA code "000000"
    And I submit the MFA verification form
    Then I should see "Invalid authentication code"
    And I should not be logged in yet

  Scenario: User successfully logs in with backup code
    Given I have MFA enabled with backup codes
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    And I enter a valid backup code
    And I submit the backup code verification form
    Then I should be redirected to the dashboard
    And I should see "Successfully authenticated with backup code"
    And I should be logged in
    And the backup code should be marked as used

  Scenario: User cannot login with invalid backup code
    Given I have MFA enabled with backup codes
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    And I enter an invalid backup code "INVALID1"
    And I submit the backup code verification form
    Then I should see "Invalid or already used backup code"
    And I should not be logged in yet

  Scenario: User cannot reuse a backup code
    Given I have MFA enabled with backup codes
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    And I enter a valid backup code
    And I submit the backup code verification form
    And I should be logged in
    When I logout
    When I login with email "user@example.com" and password "Password123!"
    And I enter the same backup code
    And I submit the backup code verification form
    Then I should see "Invalid or already used backup code"
    And I should not be logged in yet

  Scenario: OAuth users bypass MFA during login
    When I logout
    And I am an OAuth user
    When I login via OAuth
    Then I should be redirected to the dashboard
    And I should be logged in
    And I should not see MFA verification page