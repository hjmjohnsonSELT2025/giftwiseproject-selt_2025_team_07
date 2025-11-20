Feature: User Sign Up
  As a new user
  I want to create an account with my email and password
  So that I can start using Gift Wise to manage events and recipients

  Background:
    Given I am on the sign up page

  Scenario: Successful sign up with required fields only
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "john@example.com"
    And I fill in "Password" with "Password1!"
    And I click "Create Account"
    Then I should be on the dashboard page
    And I should see "Welcome to GiftWise, John Doe!"

  Scenario: Successful sign up with all fields
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "john@example.com"
    And I fill in "Password" with "Password1!"
    And I fill in "Date of Birth" with "1990-01-01"
    And I fill in "Phone Number" with "(123) 456-7890"
    And I select "Male" from "Gender"
    And I fill in "Occupation" with "Developer"
    And I fill in "Hobbies & Interests" with "Coding, Reading"
    And I fill in "Things You Like" with "Coffee"
    And I fill in "Things You Dislike" with "Bugs"
    And I click "Create Account"
    Then I should be on the dashboard page

  Scenario: Sign up fails with missing name
    When I fill in "Email Address" with "test@example.com"
    And I fill in "Password" with "Password1!"
    And I click "Create Account"
    Then I should see "Name can't be blank"

  Scenario: Sign up fails with missing email
    When I fill in "Full Name" with "John Doe"
    And I fill in "Password" with "Password1!"
    And I click "Create Account"
    Then I should see "Email can't be blank"

  Scenario: Sign up fails with invalid email format
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "invalid-email"
    And I fill in "Password" with "Password1!"
    And I click "Create Account"
    Then I should see "Email is invalid"

  Scenario: Sign up fails with weak password
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "john@example.com"
    And I fill in "Password" with "weak"
    And I click "Create Account"
    Then I should see "Password must be at least 8 characters and include uppercase, lowercase, number, and special character"

  Scenario: Sign up fails with duplicate email
    Given a user exists with email "existing@example.com"
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "existing@example.com"
    And I fill in "Password" with "Password1!"
    And I click "Create Account"
    Then I should see "Email has already been taken"

  Scenario: Sign up fails with invalid phone number
    When I fill in "Full Name" with "John Doe"
    And I fill in "Email Address" with "john@example.com"
    And I fill in "Password" with "Password1!"
    And I fill in "Phone Number" with "123"
    And I click "Create Account"
    Then I should see "Phone number is not a valid phone number"

  Scenario: Navigation to login page from sign up
    When I click "Log In"
    Then I should be on the login page

  Scenario: Navigation to home page from sign up
    When I click "Back to Home"
    Then I should be on the home page

  Scenario: Required fields show a red asterisk on the signup form
    Given I am on the signup page
    Then I should see "Full Name *"
    And I should see "Email Address *"
    And I should see "Password *"
