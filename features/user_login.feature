Feature: User Log In
  As a registered user
  I want to log in with my email and password
  So that I can access my events and recipients securely

  Background:
    Given a user exists with email "user@example.com" and password "password123" and name "Test User"


  Scenario: Login fails with incorrect email
    Given I am on the login page
    When I fill in "Email Address" with "wrong@example.com"
    And I fill in "Password" with "password123"
    And I click "Log In"
    Then I should see "Invalid email or password"
    And I should be on the login page

  Scenario: Login fails with incorrect password
    Given I am on the login page
    When I fill in "Email Address" with "user@example.com"
    And I fill in "Password" with "wrongpassword"
    And I click "Log In"
    Then I should see "Invalid email or password"
    And I should be on the login page

  Scenario: Login fails with empty email
    Given I am on the login page
    When I fill in "Password" with "password123"
    And I click "Log In"
    Then I should see "Invalid email or password"

  Scenario: Login fails with empty password
    Given I am on the login page
    When I fill in "Email Address" with "user@example.com"
    And I click "Log In"
    Then I should see "Invalid email or password"

  Scenario: Navigation to sign up page from login
    Given I am on the login page
    When I click "Sign Up"
    Then I should be on the sign up page

  Scenario: Navigation to home page from login
    Given I am on the login page
    When I click "Back to Home"
    Then I should be on the home page

  Scenario: Logged in user is redirected from home to dashboard
    Given I am logged in as "user@example.com"
    When I visit the home page
    Then I should be on the dashboard page

