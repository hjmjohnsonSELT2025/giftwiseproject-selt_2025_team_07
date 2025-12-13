#features/step_definitions/profile_steps.rb
Given('I am on the edit profile page') do
  visit edit_profile_path
end

Then('I should be on the edit profile page') do
  expect(current_path).to eq(edit_profile_path)
end

When('I visit the edit profile page') do
  visit edit_profile_path
end

Given("I am on the change password page") do
  visit edit_password_path
end
