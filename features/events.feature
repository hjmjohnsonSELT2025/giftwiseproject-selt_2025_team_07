Feature: Event Management
  As a logged-in user
  I want to create and manage events
  So that I can plan gift-giving occasions

  Background:
    Given a user exists with email "john@example.com" and password "password123"
    And I am logged in as "john@example.com" with password "password123"

  Scenario: Successfully create event with all fields
    Given I am on the dashboard page
    When I click on the "Create Event" button
    Then I should be on the new event page
    When I fill in "Event Name" with "Mom's Birthday Party"
    And I fill in "Event Date" with a future date "2025-12-25"
    And I fill in "Location" with "Home"
    And I fill in "Budget" with "500"
    And I fill in "Description" with "Surprise birthday celebration"
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And I should see a success message "Event 'Mom's Birthday Party' created successfully!"
    And the event count should be "1"
    And the event "Mom's Birthday Party" should be saved in the database

  Scenario: Successfully create event with only required fields
    Given I am on the new event page
    When I fill in "Event Name" with "Team Meeting"
    And I fill in "Event Date" with tomorrow's date
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And I should see a success message "Event 'Team Meeting' created successfully!"
    And the event "Team Meeting" should be saved in the database
    And the event "Team Meeting" should have empty location
    And the event "Team Meeting" should have null budget

  Scenario: Successfully create event with today's date
    Given I am on the new event page
    When I fill in "Event Name" with "Today's Event"
    And I fill in "Event Date" with today's date
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And I should see a success message "Event 'Today's Event' created successfully!"
    And the event should appear in upcoming events

  Scenario: Successfully create event with zero budget
    Given I am on the new event page
    When I fill in "Event Name" with "Free Event"
    And I fill in "Event Date" with tomorrow's date
    And I fill in "Budget" with "0"
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And the event "Free Event" should have budget "0.0"

  Scenario: Successfully create event with decimal budget
    Given I am on the new event page
    When I fill in "Event Name" with "Dinner Party"
    And I fill in "Event Date" with tomorrow's date
    And I fill in "Budget" with "499.99"
    And I click "Create Event" button
    Then the event "Dinner Party" should have budget "499.99"

  Scenario: Successfully create event with recipients
    Given I have recipients "Mom" and "Dad"
    And I am on the new event page
    When I fill in "Event Name" with "Family Dinner"
    And I fill in "Event Date" with tomorrow's date
    And I select recipient "Mom"
    And I select recipient "Dad"
    And I click "Create Event" button
    Then the event "Family Dinner" should have 2 recipients
    And the event should be associated with "Mom" and "Dad"

  Scenario: Fail to create event without event name
    Given I am on the new event page
    When I fill in "Event Date" with tomorrow's date
    And I fill in "Location" with "Home"
    And I click "Create Event" button
    Then I should remain on the new event page
    And I should see an error message "Event name can't be blank"
    And no event should be created
    And the form should retain the entered data

  Scenario: Fail to create event without event date
    Given I am on the new event page
    When I fill in "Event Name" with "No Date Event"
    And I click "Create Event" button
    Then I should remain on the new event page
    And I should see an error message "Event date can't be blank"
    And no event should be created

  Scenario: Fail to create event with past date (yesterday)
    Given I am on the new event page
    When I fill in "Event Name" with "Past Event"
    And I fill in "Event Date" with yesterday's date
    And I click "Create Event" button
    Then I should remain on the new event page
    And I should see an error message "Event date cannot be in the past"
    And no event should be created

  Scenario: Fail to create event with negative budget
    Given I am on the new event page
    When I fill in "Event Name" with "Negative Budget Event"
    And I fill in "Event Date" with tomorrow's date
    And I fill in "Budget" with "-100"
    And I click "Create Event" button
    Then I should remain on the new event page
    And I should see an error message "Budget must be greater than or equal to 0"
    And no event should be created

  Scenario: Fail to create event with invalid budget (text)
    Given I am on the new event page
    When I fill in "Event Name" with "Invalid Budget"
    And I fill in "Event Date" with tomorrow's date
    And I fill in "Budget" with "abc"
    And I click "Create Event" button
    Then I should remain on the new event page
    And I should see an error message "Budget is not a number"
    And no event should be created

  Scenario: Fail to create event without both required fields
    Given I am on the new event page
    When I click "Create Event" button
    Then I should remain on the new event page
    And I should see an error message "Event name can't be blank"
    And I should see an error message "Event date can't be blank"
    And I should see "2 errors prevented this event from being saved"
    And no event should be created

  Scenario: Create event with special characters in name
    Given I am on the new event page
    When I fill in "Event Name" with "Mom's B'day @ Home! 🎉"
    And I fill in "Event Date" with tomorrow's date
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And the event "Mom's B'day @ Home! 🎉" should be saved in the database

  Scenario: Create multiple events with same name
    Given an event "Birthday" exists for the current user
    And I am on the new event page
    When I fill in "Event Name" with "Birthday"
    And I fill in "Event Date" with tomorrow's date
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And there should be 2 events with name "Birthday"

  Scenario: Attempt to create event without authentication
    Given I am logged out
    When I try to access the new event page
    Then I should be redirected to the login page
    And I should see an alert message "Please log in to continue"

  Scenario: Verify event is associated with correct user
    Given another user exists with email "jane@example.com"
    And I am logged in as "john@example.com" with password "password123"
    When I create an event "John's Event"
    Then the event "John's Event" should belong to user "john@example.com"
    And user "jane@example.com" should not see the event "John's Event"

  Scenario: Cancel creating event returns to dashboard
    Given I am on the new event page
    When I fill in "Event Name" with "Test Event"
    And I click "Cancel" button
    Then I should be redirected to the dashboard
    And no event should be created

  Scenario: Form retains data after validation error
    Given I am on the new event page
    When I fill in "Event Name" with "Test Event"
    And I fill in "Event Date" with yesterday's date
    And I fill in "Location" with "Home"
    And I fill in "Budget" with "100"
    And I fill in "Description" with "Test description"
    And I click "Create Event" button
    Then I should remain on the new event page
    And the "Event Name" field should contain "Test Event"
    And the "Location" field should contain "Home"
    And the "Budget" field should contain "100"
    And the "Description" field should contain "Test description"

  Scenario: Event appears in dashboard recent events after creation
    Given I am on the new event page
    When I fill in "Event Name" with "New Event"
    And I fill in "Event Date" with tomorrow's date
    And I fill in "Location" with "Park"
    And I click "Create Event" button
    Then I should be redirected to the dashboard
    And I should see "New Event" in the recent events section
    And the recent event should display "Park" as location

  Scenario: Flash message auto-dismisses after event creation
    Given I am on the new event page
    When I successfully create an event "Quick Event"
    Then I should see a success flash message
    And the flash message should disappear after 4 seconds