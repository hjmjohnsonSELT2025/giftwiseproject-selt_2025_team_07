Feature: Google OAuth Authentication
  As a user
  I want to sign in with Google
  So that I can quickly access GiftWise without creating a password

  Background:
    Given I am on the login page

  Scenario: New user signs up with Google
    When I click "Continue with Google"
    And Google authentication succeeds with email "newuser@example.com" and name "New User"
    Then I should be redirected to the dashboard
    And I should see "Welcome, New User!"
    And a user should exist with email "newuser@example.com"
    And the user "newuser@example.com" should have no password

  Scenario: Existing user with password links Google account
    Given a user exists with email "existing@example.com" and password "Password1!" and name "Existing User"
    When I click "Continue with Google"
    And Google authentication succeeds with email "existing@example.com" and name "Existing User"
    Then I should be redirected to the dashboard
    And I should see "Welcome, Existing User!"
    And the user "existing@example.com" should have a Google authentication

  Scenario: Returning Google user logs in
    Given a Google user exists with email "google@example.com" and name "Google User"
    When I click "Continue with Google"
    And Google authentication succeeds with email "google@example.com" and name "Google User"
    Then I should be redirected to the dashboard
    And I should see "Welcome, Google User!"

  Scenario: Google OAuth user cannot login with password
    Given a Google user exists with email "oauth@example.com" and name "OAuth User"
    And I am on the login page
    When I fill in "Email Address" with "oauth@example.com"
    And I fill in "Password" with "anypassword"
    And I click "Log In"
    Then I should see "created with Google"
    And I should see "Please use"

  Scenario: Google OAuth user can set password later
    Given a Google user exists with email "oauth@example.com" and name "OAuth User"
    And I am logged in as Google user "oauth@example.com"
    When I visit the change password page
    And I fill in "New Password" with "NewPass1!"
    And I fill in "Confirm New Password" with "NewPass1!"
    And I click "Set Password"
    Then I should see "Password updated successfully"
    And the user "oauth@example.com" should have a password

  Scenario: User with password can still use Google after linking
    Given a user exists with email "both@example.com" and password "Password1!" and name "Both User"
    And the user "both@example.com" has linked their Google account
    When I am on the login page
    And I fill in "Email Address" with "both@example.com"
    And I fill in "Password" with "Password1!"
    And I click "Log In"
    Then I should be redirected to the dashboard
    And I should see "Welcome back, Both User!"

  Scenario: Google authentication failure
    When I click "Continue with Google"
    And Google authentication fails
    Then I should be on the login page
    And I should see "Authentication failed"

  Scenario: Sign up page has Google option
    Given I am on the sign up page
    Then I should see "Sign up with Google"
    And I should see "Or sign up with email"