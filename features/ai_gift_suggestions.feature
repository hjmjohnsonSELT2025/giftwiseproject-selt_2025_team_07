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

  Scenario: Regenerating AI ideas never repeats previous suggestions
  # Background already logs me in as test@example.com
    Given I have an event "Birthday" with a recipient "Alex"
    And AI gift suggestions already exist for "Alex" on "Birthday":
      | title           |
      | Cozy Blanket    |
      | Wireless Mouse  |
    When I go to the AI gift suggestions page for "Birthday"
    And I click "Regenerate ideas" for "Alex"
    Then I should see 5 AI gift ideas for "Alex"
    And I should not see "Cozy Blanket"
    And I should not see "Wireless Mouse"

  Scenario: Browsing AI gift library with filters
    # Background already logs me in as test@example.com
    Given I have an event "Birthday" with a recipient "Alex"
    And AI gift suggestions already exist for "Alex" on "Birthday":
      | title        | category | saved_to_wishlist |
      | Smartwatch   | Tech     | true              |
      | Garden Book  | Books    | false             |
    When I visit the AI gift library
    And I filter the AI library by event "Birthday" and recipient "Alex" and saved only
    Then I should see "Smartwatch"
    And I should not see "Garden Book"
