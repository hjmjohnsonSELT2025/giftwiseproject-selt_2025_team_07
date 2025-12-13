Feature: Event collaborations (dashboard + event page)

  Background:
    Given a user exists with email "owner@example.com" and password "Password1!" and name "Owner"
    And a user exists with email "viewer@example.com" and password "Password1!" and name "Viewer"
    And a user exists with email "planner@example.com" and password "Password1!" and name "Planner"

  Scenario: Accepted collaborator sees collaboration badge on dashboard and can open event
    Given there is an event "Collab Party" owned by "owner@example.com" happening in 10 days
    And the event "Collab Party" has a recipient "Alice"
    And "viewer@example.com" is an accepted "viewer" collaborator on event "Collab Party"

    When I log in as "viewer@example.com" with password "Password1!"
    And I go to the dashboard
    Then I should see "Collab Party"
    And I should see "Collaboration"

    When I open the event "Collab Party" from the dashboard
    Then I should see "Collaborators"
    And I should not see "Edit Event"
    And the "Get Ideas" action should be disabled

  Scenario: Accepted co-planner can manage gifts and sees Get Ideas link on event
    Given there is an event "Planning Night" owned by "owner@example.com" happening in 12 days
    And the event "Planning Night" has a recipient "Bob"
    And "planner@example.com" is an accepted "co_planner" collaborator on event "Planning Night"

    When I log in as "planner@example.com" with password "Password1!"
    And I visit the event page for "Planning Night"
    Then I should see "Get Ideas"
    And I should see "Edit Event"

  Scenario: Owner can invite a collaborator from event page
    Given there is an event "Owner Event" owned by "owner@example.com" happening in 15 days

    When I log in as "owner@example.com" with password "Password1!"
    And I visit the event page for "Owner Event"
    Then I should see "Invite a collaborator"
    And I should see "Invite by email"
    And I should see "Role"
    And I should see "Invite"

  Scenario: Pending invite is not accessible until accepted (no badge, no access)
    Given there is an event "Pending Event" owned by "owner@example.com" happening in 8 days
    And "viewer@example.com" is a pending "viewer" collaborator on event "Pending Event"

    When I log in as "viewer@example.com" with password "Password1!"
    And I go to the dashboard
    Then I should not see "Pending Event"

    When I accept the collaboration for "viewer@example.com" on event "Pending Event"
    And I go to the dashboard
    Then I should see "Pending Event"
    And I should see "Collaboration"
