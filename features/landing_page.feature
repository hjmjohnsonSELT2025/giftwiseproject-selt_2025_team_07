Feature: Public Landing Page
  As a visitor
  I want to see the GiftWise landing page
  So that I can understand the product and get started

  Background:
    Given I am on the home page


  Scenario: Hero copy and CTAs are visible
    Then I should see "Find the Perfect"
    And I should see "Gift, Every Time"
    And I should see a "Get Started" button
    And I should see a "See How It Works" button

  Scenario: Section anchors exist for in-page navigation
    Then the page should have a section with id "features"
    And the page should have a section with id "how-it-works"
    And the page should have a section with id "about"

  Scenario: Clicking the How It Works CTA moves to the section
    When I click "See How It Works"
    Then I should be at the "how-it-works" section
    And I should see "How GiftWise Works"

  Scenario: How It Works shows four violet cards with step numbers and titles
    Then I should see the step "01" with title "Create Profiles"
    And I should see the step "02" with title "Get Recommendations"
    And I should see the step "03" with title "Choose & Purchase"
    And I should see the step "04" with title "Track & Delight"

  @wip @javascript
  Scenario: Get Started opens the auth modal (placeholder)
    When I click "Get Started"
    Then I should see the auth modal
