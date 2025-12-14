Feature: Cart
  As a user
  I want to manage items in my cart
  So that I can place an order (COD)

  Background:
    Given I am logged in

  Scenario: View cart
    When I visit the cart page
    Then I should see "Cart"

  Scenario: Add item to cart
    Given an AI gift suggestion exists
    When I add that suggestion to the cart
    Then I should see "Added to cart"

  Scenario: Clear cart
    Given my cart has at least one item
    When I clear the cart
    Then I should see "Cart cleared"
