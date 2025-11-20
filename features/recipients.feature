Feature: Manage recipients
  As a logged-in user
  I want to create, view, edit, and delete recipients
  So I can manage people I give gifts to

  Background:
    Given I am logged in

  Scenario: View list of recipients
    When I visit the recipients page
    Then I should see the list of my recipients


  Scenario: Create a new recipient successfully
    When I visit the new recipient page
    And I fill in "Name" with "John"
    And I fill in "Email" with "john@example.com"
    And I fill in "Relationship" with "Friend"
    And I select "Male" from "Gender"
    And I submit the recipient form
    Then I should be redirected to the dashboard



  Scenario: Fail to create recipient without required name
    When I visit the new recipient page
    And I fill in "Email" with "no-name@example.com"
    And I submit the recipient form
    Then I should see "Name can't be blank"

  Scenario: Edit a recipient
    Given a recipient named "Mani" exists
    When I edit the recipient "Mani"
    And I change the name to "Mani Updated"
    And I submit the updated recipient form


  Scenario: Delete a recipient
    Given a recipient named "Ayra" exists
    When I delete the recipient "Ayra"
    Then I should not see "Ayra"

  Scenario: Required fields on the new recipient form show a red asterisk
    Given I am on the new recipient page
    Then I should see "Name *"
    And I should see "Email *"
    And I should see "Relationship *"
    And I should see "Gender *"

  Scenario: Required fields on the edit recipient form show a red asterisk
    Given a recipient named "Mani" exists
    When I edit the recipient "Mani"
    Then I should see "Name *"
    And I should see "Email *"
    And I should see "Relationship *"
    And I should see "Gender *"

