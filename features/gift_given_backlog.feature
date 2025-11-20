Feature: Manage Gift Given Backlog
  As a user
  I want to record gifts I already gave
  So that I can track what I have gifted to each recipient

  Background:
    Given a user exists with email "john@example.com" and password "Password@123"
    And I am logged in as "john@example.com" with password "Password@123"
    And a recipient named "Alice" exists for the current user
    And I am on the recipients page



  Scenario: Cancel gift given creation
    When I click "Gift Given" for "Alice"
    And I press "Cancel"
    Then I should be on the recipient page for "Alice"
    And I should not see any new gift given added to the backlog table

  Scenario: Gift name is mandatory when adding a gift given
    When I click "Gift Given" for "Alice"
    And I fill in the gift given form with an empty gift name
    And I press "Save"



  Scenario: Required fields on the gift given form show a red asterisk
    When I click "Gift Given" for "Alice"
    Then I should see "Gift name *"
