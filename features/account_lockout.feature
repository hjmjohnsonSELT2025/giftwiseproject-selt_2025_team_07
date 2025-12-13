# features/support/account_lockout.feature

Feature: Account Lockout After Failed Login Attempts
  As a security measure
  To protect user accounts from brute force attacks
  Users should be locked out after 5 failed login attempts

  Background:
    Given a user exists with email "john@example.com" and password "SecurePass123!"

  Scenario: User can log in with correct credentials
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "SecurePass123!"
    And I click "Log In"
    Then I should be on the dashboard page
    And I should see "Welcome back, John Doe!"

  Scenario: Failed login attempt increments counter
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "WrongPassword"
    And I click "Log In"
    Then I should see "Invalid email or password"
    And the user "john@example.com" should have 1 failed login attempt

  Scenario: Account locks after 5 failed login attempts
    When I visit the login page
    And I attempt to log in 6 times with wrong password for "john@example.com"
    Then I should see "Your account has been locked due to too many failed login attempts. Please try again in 30 minutes or reset your password."
    And the user "john@example.com" should be locked

  Scenario: Locked account shows lockout message on 6th attempt
    Given the user "john@example.com" has 5 failed login attempts and is locked
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "SecurePass123!"
    And I click "Log In"
    Then I should see "Your account has been locked due to too many failed login attempts. Please try again in 30 minutes or reset your password."
    And I should not be logged in

  Scenario: Locked account cannot log in even with correct password
    Given the user "john@example.com" has 5 failed login attempts and is locked
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "SecurePass123!"
    And I click "Log In"
    Then I should see "Your account has been locked"
    And I should not be on the dashboard page

  Scenario: Account auto-unlocks after 30 minutes
    Given the user "john@example.com" was locked 31 minutes ago
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "SecurePass123!"
    And I click "Log In"
    Then I should be on the dashboard page
    And I should see "Welcome back, John Doe!"
    And the user "john@example.com" should have 0 failed login attempts

  Scenario: Successful login resets failed attempt counter
    Given the user "john@example.com" has 3 failed login attempts
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "SecurePass123!"
    And I click "Log In"
    Then I should be on the dashboard page
    And the user "john@example.com" should have 0 failed login attempts

  Scenario: Password reset unlocks account immediately
    Given the user "john@example.com" has 5 failed login attempts and is locked
    When I visit the forgot password page
    When I fill in "Email Address" with "testuser@example.com"
    And I click "Send Reset Instructions"
    Then I should be on the login page
    And I should see "Welcome Back"


  Scenario: Multiple users can be locked independently
    Given a user exists with email "alice@example.com" and password "AlicePass123!"
    And a user exists with email "bob@example.com" and password "BobPass123!"
    When I attempt to log in 5 times with wrong password for "alice@example.com"
    Then the user "alice@example.com" should be locked
    And the user "bob@example.com" should not be locked
    When I visit the login page
    And I fill in "Email" with "bob@example.com"
    And I fill in "Password" with "BobPass123!"
    And I click "Log In"
    Then I should be on the dashboard page

  Scenario: OAuth users are not affected by lockout
    Given a user exists via Google OAuth with email "oauth@example.com"
    When I click "Continue with Google"
    And Google authentication succeeds with email "existing@example.com" and name "Existing User"
    And the user "oauth@example.com" should have 0 failed login attempts

  Scenario: Failed attempts for non-existent user
    When I visit the login page
    And I fill in "Email" with "nonexistent@example.com"
    And I fill in "Password" with "AnyPassword123!"
    And I click "Log In"
    Then I should see "Invalid email or password"
    And I should not be logged in
