Feature: Manage Gift Ideas
  As a user
  I want to add and manage gift ideas
  So that I can plan gifts for each recipient

  Background:
    Given a recipient with an event exists
    And I am on the recipients page

  Scenario: Add a gift idea successfully
    When I click the Gift Idea button
    And I fill in the gift idea form correctly
    And I press "Save"
    Then I should be on the recipient page

  Scenario: Cancel gift idea creation
    When I click the Gift Idea button
    And I press "Cancel"
    Then I should be on the recipients page

  Scenario: Gift idea validation errors
    When I click the Gift Idea button
    And I press "Save"
    Then I should see "can't be blank"

  Scenario: Disabled Gift Idea button for recipients without events
    Given a recipient without an event exists
    When I am on the recipients page
    Then the Gift Idea button should be disabled

  Scenario: Required fields on the gift idea form show a red asterisk
    When I click the Gift Idea button
    Then I should see "Gift Idea *"

