Feature: Profile Update
  As a logged-in user
  I want to update my profile information
  So that I can keep my account information current

  Background:
    Given a user exists with email "john@example.com" and password "Password1!" and name "John Doe"
    And I am logged in as "john@example.com"

  Scenario: User navigates to edit profile page
    Given I am on the dashboard page
    When I click "Edit Profile"
    Then I should be on the edit profile page
    And I should see "Edit Profile"
    And I should see "Update your personal information"

  Scenario: User successfully updates required fields
    Given I am on the edit profile page
    When I fill in "Full Name" with "John Updated"
    And I fill in "Email Address" with "johnupdated@example.com"
    And I click "Update Profile"
    Then I should be on the dashboard page
    And I should see "Profile updated successfully"
    And I should see "Welcome, John Updated!"

  Scenario: User successfully updates optional fields
    Given I am on the edit profile page
    When I fill in "Date of Birth" with "1990-01-01"
    And I fill in "Phone Number" with "(123) 456-7890"
    And I select "Male" from "Gender"
    And I fill in "Occupation" with "Software Engineer"
    And I fill in "Hobbies and Interests" with "Reading, coding"
    And I fill in "Things You Like" with "Coffee, music"
    And I fill in "Things You Dislike" with "Spam calls"
    And I click "Update Profile"
    Then I should be on the dashboard page
    And I should see "Profile updated successfully"

  Scenario: User enters mismatched passwords
    Given I am on the change password page
    When I fill in "New Password" with "NewPass1!"
    And I fill in "Confirm New Password" with "DifferentPass1!"
    And I click "Update Password"
    Then I should see "Password confirmation doesn't match Password"

  Scenario: User leaves password fields blank (no password change)
    Given I am on the edit profile page
    When I fill in "Full Name" with "John NoPasswordChange"
    And I click "Update Profile"
    Then I should be on the dashboard page
    And I should see "Profile updated successfully"

  Scenario: User enters mismatched passwords
    Given I am on the change password page
    When I fill in "New Password" with "NewPass1!"
    And I fill in "Confirm New Password" with "DifferentPass1!"
    And I click "Update Password"
    Then I should see "Password confirmation doesn't match Password"

  Scenario: User enters weak password
    Given I am on the change password page
    When I fill in "New Password" with "weak"
    And I fill in "Confirm New Password" with "weak"
    And I click "Update Password"
    Then I should see "Password must be at least 8 characters and include uppercase, lowercase, number, and special character"

  Scenario: User clears required name field
    Given I am on the edit profile page
    When I fill in "Full Name" with ""
    And I click "Update Profile"
    Then I should see "Name can't be blank"

  Scenario: User enters invalid email format
    Given I am on the edit profile page
    When I fill in "Email Address" with "invalidemail"
    And I click "Update Profile"
    Then I should see "Email is invalid"

  Scenario: User enters duplicate email
    Given a user exists with email "existing@example.com"
    And I am on the edit profile page
    When I fill in "Email Address" with "existing@example.com"
    And I click "Update Profile"
    Then I should see "Email has already been taken"

  Scenario: User enters invalid phone number
    Given I am on the edit profile page
    When I fill in "Phone Number" with "123"
    And I click "Update Profile"
    Then I should see "Phone number is not a valid phone number"

  Scenario: User cancels profile update
    Given I am on the edit profile page
    When I click "Cancel"
    Then I should be on the dashboard page

  Scenario: Unauthenticated user cannot access edit profile
    Given I click "Log Out"
    When I visit the edit profile page
    Then I should be on the login page
    And I should see "Please log in to continue"

  Scenario: Required fields on Edit Profile show asterisk
    Given I am logged in
    And I am on the edit profile page
    Then I should see "Full Name *"
    And I should see "Email Address *"