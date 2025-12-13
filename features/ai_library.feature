Feature: AI Gift Library scopes and filters

  Background:
    Given I am logged in as "owner@example.com"
    And there is an owned event with AI ideas for "owner@example.com"
    And there is a collaboration event accessible to "owner@example.com" with AI ideas from "other@example.com"

  Scenario: Switching to Collab scope shows only collaboration events
    When I visit the AI Gift Library page
    And I click "Collab"
    Then I should see "Collab Event"
    And I should not see "Owned Event"

  Scenario: Scope remains Collab after applying filters
    When I visit the AI Gift Library page
    And I click "Collab"
    And I click "Apply filters"
    Then I should see "Collab Event"
    And I should not see "Owned Event"

  Scenario: Category dropdown shows categories from visible scope
    When I visit the AI Gift Library page
    And I click "Collab"
    Then the category dropdown should include "Tech"
    And the category dropdown should not include "Books"
