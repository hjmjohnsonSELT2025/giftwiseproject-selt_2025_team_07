Feature: Orders
  As a user
  I want to place orders from my cart
  So that I can track delivery

  Background:
    Given I am logged in

  Scenario: View orders list
    When I visit the orders page
    Then I should see "My Orders"

  Scenario: Place an order (COD)
    Given my cart has at least one item
    When I place an order with delivery info
    Then I should see "My Orders"
