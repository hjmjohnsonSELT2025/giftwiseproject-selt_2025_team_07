Feature: AI gift suggestions
  As a logged-in user
  I want to generate AI gift ideas for my event recipients
  So that I can quickly find good gift options

  Background:
    Given a user exists with email "test@example.com" and password "Password1!"
    And I am logged in as "test@example.com" with password "Password1!"

  Scenario: Event with recipients shows enabled Get Ideas button
    Given I have an upcoming event "Mom's Birthday" with a recipient "Mom"
    When I visit the dashboard
    Then I should see an enabled "Get Ideas" button for "Mom's Birthday"

  Scenario: Event without recipients shows disabled Get Ideas button
    Given I have an upcoming event "Team Party" with no recipients
    When I visit the dashboard
    Then I should see a disabled "Get Ideas" button for "Team Party"
