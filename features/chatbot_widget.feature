#Feature: Chatbot widget on dashboard
#  As a logged in user
#  I want to see the GiftWise Assistant widget
#  So that I know I can ask questions about my events
#
#  Background:
#    Given a chatbot test user exists
#    And I am logged in as the chatbot test user
#
#  Scenario: Dashboard shows chatbot button
#    When I visit the dashboard page
#    Then I should see the chatbot button
#
#  Scenario: I can open the chatbot panel
#    When I visit the dashboard page
#    And I click the chatbot button
#    Then I should see the chatbot panel
#
##  Scenario: I can open and close the chatbot panel
##    When I visit the dashboard page
##    And I click the chatbot button
##    And I close the chatbot panel
##    Then the chatbot panel should be hidden


Feature: Chatbot widget on dashboard
  As a logged in user
  I want to see the GiftWise Assistant widget
  So that I know I can ask questions about my events

  Background:
    Given a chatbot test user exists
    And I am logged in as the chatbot test user

  Scenario: Dashboard shows chatbot button
    When I visit the dashboard page
    Then I should see the chatbot button

  Scenario: I can open the chatbot panel
    When I visit the dashboard page
    And I click the chatbot button
    Then I should see the chatbot panel

#  Scenario: I can open and close the chatbot panel
#    When I visit the dashboard page
#    And I click the chatbot button
#    And I close the chatbot panel
#    Then the chatbot panel should be hidden

  Scenario: Chatbot panel shows header
    When I visit the dashboard page
    And I click the chatbot button
    Then I should see the chatbot header

  Scenario: Chatbot panel shows input box
    When I visit the dashboard page
    And I click the chatbot button
    Then I should see the chatbot input field
