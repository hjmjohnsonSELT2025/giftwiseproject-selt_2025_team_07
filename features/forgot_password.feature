Feature: Password Reset
  As a user who forgot their password
  I want to request a password reset link via email
  So that I can set a new password and access my account

  Background:
    Given the following user exists:
      | name        | email                  | password    |
      | Test User   | testuser@example.com   | Password1!  |

  Scenario: User navigates to forgot password page from login
    Given I am on the login page
    When I click "Forgot your password?"
    Then I should be on the forgot password page
    And I should see "Reset Your Password"
    And I should see "Enter your email address and we'll send you a link to reset your password"

  Scenario: User requests password reset with valid email
    Given I am on the forgot password page
    When I fill in "Email Address" with "testuser@example.com"
    And I click "Send Reset Instructions"
    Then I should be on the login page
    And I should see "Welcome Back"
    And a password reset email should be sent to "testuser@example.com"
    And the email should contain a password reset link
    And the email should be from "noreply@mygiftwise.online"

  Scenario: User requests password reset with valid email in different case
    Given I am on the forgot password page
    When I fill in "Email Address" with "TestUser@Example.COM"
    And I click "Send Reset Instructions"
    Then I should be on the login page
    And I should see "Welcome Back"
    And a password reset email should be sent to "testuser@example.com"

  Scenario: User requests password reset with invalid email
    Given I am on the forgot password page
    When I fill in "Email Address" with "nonexistent@example.com"
    And I click "Send Reset Instructions"
    Then I should be on the forgot password page
    And I should see "No account found with that email address"
    And no password reset email should be sent

  Scenario: User requests password reset with blank email
    Given I am on the forgot password page
    When I click "Send Reset Instructions"
    Then I should be on the forgot password page
    And I should see "No account found with that email address"

  Scenario: User clicks valid reset link and sees reset form
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    Then I should see "Reset Your Password"
    And I should see "New Password"
    And I should see "Confirm New Password"
    And I should see a "Reset Password" button

  Scenario: User successfully resets password with valid credentials
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "NewPassword1!"
    And I fill in "Confirm New Password" with "NewPassword1!"
    And I click "Reset Password"
    Then I should be on the login page
    And I should see "Welcome Back"
#    And I should see "Password successfully reset. Please log in with your new password."
    When I fill in "Email Address" with "testuser@example.com"
    And I fill in "Password" with "NewPassword1!"
    And I click "Log In"
    Then I should be on the dashboard page
    And I should not see "Invalid email or password"

  Scenario: User cannot login with old password after reset
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "NewPassword1!"
    And I fill in "Confirm New Password" with "NewPassword1!"
    And I click "Reset Password"
    And I am on the login page
    When I fill in "Email Address" with "testuser@example.com"
    And I fill in "Password" with "Password1!"
    And I click "Log In"
    Then I should be on the login page
    And I should see "Invalid email or password"

  Scenario: User tries to use expired reset link
    Given an expired password reset token exists for "testuser@example.com"
    When I visit the password reset link
    Then I should be on the forgot password page
    And I should see "This password reset link has expired. Please request a new one."

  Scenario: User tries to use invalid reset link
    When I visit an invalid password reset link
    Then I should be on the login page
    And I should see "Invalid or expired password reset link"

  Scenario: User tries to reuse a password reset link
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "NewPassword1!"
    And I fill in "Confirm New Password" with "NewPassword1!"
    And I click "Reset Password"
    Then I should see "Welcome Back"
    When I visit the same password reset link again
    Then I should be on the login page
    And I should see "Invalid or expired password reset link"

  Scenario: User tries to use already used reset link directly
    Given a used password reset token exists for "testuser@example.com"
    When I visit the password reset link
    Then I should be on the login page
    And I should see "Invalid or expired password reset link"

  Scenario: User enters passwords that don't match
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "NewPassword1!"
    And I fill in "Confirm New Password" with "DifferentPassword1!"
    And I click "Reset Password"
    Then I should see "Reset Your Password"
    And I should see "Password confirmation doesn't match Password"

  Scenario: User enters password without uppercase letter
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "password1!"
    And I fill in "Confirm New Password" with "password1!"
    And I click "Reset Password"
    Then I should see "Password must contain at least one uppercase letter"

  Scenario: User enters password without lowercase letter
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "PASSWORD1!"
    And I fill in "Confirm New Password" with "PASSWORD1!"
    And I click "Reset Password"
    Then I should see "Password must contain at least one lowercase letter"

  Scenario: User enters password without number
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "Password!"
    And I fill in "Confirm New Password" with "Password!"
    And I click "Reset Password"
    Then I should see "Password must contain at least one number"

  Scenario: User enters password without special character
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "Password1"
    And I fill in "Confirm New Password" with "Password1"
    And I click "Reset Password"
    Then I should see "Password must contain at least one special character"

  Scenario: User enters password that is too short
    Given a password reset token exists for "testuser@example.com"
    When I visit the password reset link
    And I fill in "New Password" with "Pass1!"
    And I fill in "Confirm New Password" with "Pass1!"
    And I click "Reset Password"
    Then I should see "is too short"

  Scenario: User requests multiple password resets
    Given I am on the forgot password page
    When I fill in "Email Address" with "testuser@example.com"
    And I click "Send Reset Instructions"
    And I am on the forgot password page
    And I fill in "Email Address" with "testuser@example.com"
    And I click "Send Reset Instructions"
    Then 2 password reset emails should be sent to "testuser@example.com"
    And both reset links should work independently

  Scenario: Multiple users can request password resets
    Given the following user exists:
      | name          | email                  | password    |
      | Another User  | anotheruser@example.com| Password1!  |
    And I am on the forgot password page
    When I fill in "Email Address" with "testuser@example.com"
    And I click "Send Reset Instructions"
    And I am on the forgot password page
    And I fill in "Email Address" with "anotheruser@example.com"
    And I click "Send Reset Instructions"
    Then a password reset email should be sent to "testuser@example.com"
    And a password reset email should be sent to "anotheruser@example.com"

  Scenario: Reset link expires after 1 hour
    Given a password reset token was created 59 minutes ago for "testuser@example.com"
    When I visit the password reset link
    Then I should see "Reset Your Password"
    And I should be able to reset my password

  Scenario: Reset link is expired after more than 1 hour
    Given a password reset token was created 61 minutes ago for "testuser@example.com"
    When I visit the password reset link
    Then I should be on the forgot password page
    And I should see "This password reset link has expired"