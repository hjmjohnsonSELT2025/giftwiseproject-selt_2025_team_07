Feature: User Sign Up
  As a new user
  I want to create an account with my email and password
  So that I can start using Gift Wise to manage events and recipients

  Background:
    Given I am on the sign up page


  Scenario: Sign up fails with missing name
    When I fill in "Email Address" with "test@example.com"
    And I fill in "Password" with "password123"
    And I click "Create Account"
    Then I should see "Name can't be blank"

  Scenario: Sign up fails with missing email
    When I fill in "Full Name" with "John Doe"
    And I fill in "Password" with "password123"
    And I click "Create Account"
    Then I should see "Email can't be blank"

  Scenario: Sign up fails with invalid email format
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "invalid-email"
    And I fill in "Password" with "password123"
    And I click "Create Account"
    Then I should see "Email is invalid"

  Scenario: Sign up fails with short password
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "john@example.com"
    And I fill in "Password" with "short"
    And I click "Create Account"
    Then I should see "Password is too short"

  Scenario: Sign up fails with duplicate email
    Given a user exists with email "existing@example.com"
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "existing@example.com"
    And I fill in "Password" with "password123"
    And I click "Create Account"
    Then I should see "Email has already been taken"

  Scenario: Navigation to login page from sign up
    When I click "Log In"
    Then I should be on the login page

  Scenario: Navigation to home page from sign up
    When I click "Back to Home"
    Then I should be on the home page