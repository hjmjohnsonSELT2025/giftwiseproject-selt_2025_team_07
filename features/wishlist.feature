Feature: Wishlist
  As a logged-in user
  I want to see and manage my saved gift ideas
  So that I can easily review gifts I liked

  Background:
    Given a user exists with email "test@example.com" and password "Password1!"
    And I am logged in as "test@example.com" with password "Password1!"

  Scenario: Wishlist page shows saved items
    Given I have a wishlist idea titled "Cozy Blanket" for recipient "Mom" and event "Mom's Birthday"
    When I visit the wishlist page
    Then I should see "Cozy Blanket" in my wishlist
    And I should see "Mom" in my wishlist
    And I should see "Mom's Birthday" in my wishlist

  Scenario: Empty wishlist shows empty state message
    Given I have no wishlist items
    When I visit the wishlist page
    Then I should see the empty wishlist message
