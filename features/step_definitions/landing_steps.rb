
Given('I am on the home page') do
  visit root_path
end


Then('I should see a {string} button') do |button_text|
  begin
    expect(page).to have_link(button_text)
  rescue RSpec::Expectations::ExpectationNotMetError
    expect(page).to have_button(button_text)
  end
end

Then('the page should have a section with id {string}') do |section_id|
  expect(page).to have_css("##{section_id}", visible: :all)
end

Then('I should be at the {string} section') do |section_id|
  expect(page).to have_css("##{section_id}", visible: true)
end

Then('I should see the step {string} with title {string}') do |step_number, title|
  within('#how-it-works') do
    expect(page).to have_content(step_number)
    expect(page).to have_content(title)
  end
end

Then('I should see the auth modal') do
  pending "Wire up the auth modal and add a real selector here, e.g. '.auth-modal'"
end
