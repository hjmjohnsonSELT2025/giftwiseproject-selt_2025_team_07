Feature: Dashboard and events overview
  As a logged in user
  I want to see my upcoming events on the dashboard
  So that I can quickly jump to the event details or see all events

  Background:
    Given a user exists with email "user@example.com" and password "password"
    And that user has the following events:
      | event_name       | event_date  | budget | location   |
      | Anniversary      | 2025-11-19  | 150    | Restaurant |
      | Mom's Birthday   | 2025-12-14  | 80     | Home       |
      | Old Event        | 2024-01-01  | 20     | Home       |
    And I am logged in as "user@example.com" with password "password"

  Scenario: Dashboard shows upcoming events
    When I visit the dashboard
    Then I should see "Anniversary" within the upcoming events section
    And I should see "Mom's Birthday" within the upcoming events section
    And I should not see "Old Event" within the upcoming events section

  Scenario: Dashboard upcoming event links to event details
    When I visit the dashboard
    And I click on the event "Anniversary" in the upcoming events section
    Then I should be on the event details page for "Anniversary"
    And I should see "Restaurant"
    And I should see "$150"

  Scenario: Dashboard 'View all' shows all events grouped
    When I visit the dashboard
    And I click "View all"
    Then I should be on the events index page
    And I should see "Anniversary"
    And I should see "Mom's Birthday"
    And I should see "Old Event"

  Scenario: Events index row opens details
    Given I am on the events index page
    When I click on the event row for "Mom's Birthday"
    Then I should be on the event details page for "Mom's Birthday"
