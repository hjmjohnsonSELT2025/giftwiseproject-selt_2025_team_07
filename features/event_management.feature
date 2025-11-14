Feature: Event management
As a logged-in user
I want to create events
So that I can plan gifts for upcoming occasions

Background:
Given a user exists with email "user@example.com" and password "password"
And I am logged in as "user@example.com" with password "password"

Scenario: Create event with all fields filled
When I visit the new event page
And I fill in the event form with:
| Event Name   | Mom's Birthday Party                |
| Event Date   | future date                         |
| Location     | Home                                |
| Budget       | 500                                 |
| Description  | Surprise birthday celebration for mom |
And I click "Create Event"
Then I should be on the dashboard page
And I should see "Event 'Mom's Birthday Party' created successfully!"

Scenario: Create event with only required fields
When I visit the new event page
And I fill in the event form with:
| Event Name | Team Meeting  |
| Event Date | tomorrow      |
And I click "Create Event"
Then I should be on the dashboard page
And I should see "Event 'Team Meeting' created successfully!"

Scenario: Fail to create event without event name
When I visit the new event page
And I fill in the event form with:
| Event Name |             |
| Event Date | tomorrow    |
And I click "Create Event"
Then I should see "Event name can't be blank"

Scenario: Fail to create event with past date
When I visit the new event page
And I fill in the event form with:
| Event Name | Past Event   |
| Event Date | yesterday    |
And I click "Create Event"
Then I should see "Event date cannot be in the past"