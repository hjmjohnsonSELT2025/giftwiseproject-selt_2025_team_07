When("I visit the home page") do
  visit root_path
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then('I should see a {string} button') do |label|
  # Works for <a> or <button>
  expect(page).to have_selector(:link_or_button, label)
end

Then('the page should have a section with id {string}') do |id|
  expect(page).to have_css("##{id}")
end

When('I click {string}') do |label|
  click_link_or_button(label)
end

Then('I should be at the {string} section') do |id|
  # With rack_test there’s no fragment in current_url; just assert section content is present.
  within("##{id}") do
    # any heading/content that proves the section is visible
    expect(page).to have_content(/How GiftWise Works|Create Profiles|Get Recommendations|Choose & Purchase|Track & Delight/)
  end
end


Then('I should see the step {string} with title {string}') do |num, title|
  within("#how-it-works") do
    # Each card contains the number and title text
    # (Don’t assert on Tailwind classes — keep it content-based)
    expect(page).to have_content(num)
    expect(page).to have_content(title)
  end
end

Then('I should see the auth modal') do
  # Placeholder selector; update when you add the modal markup
  # e.g., <div id="auth-modal" class="...">
  expect(page).to have_css("#auth-modal", visible: true)
end
