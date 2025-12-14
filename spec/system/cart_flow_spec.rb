require "rails_helper"

RSpec.describe "Cart flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { User.create!(name: "UI User", email: "ui@example.com", password: "Password@1", password_confirmation: "Password@1") }
  let!(:event) { Event.create!(user: user, event_name: "UI Event", event_date: Date.today + 7, budget: 100) }
  let!(:recipient) { Recipient.create!(user: user, name: "Alex", relationship: "Friend") }
  let!(:event_recipient) { EventRecipient.create!(event: event, recipient: recipient) }
  let!(:idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Watch",
      description: "Nice watch",
      category: "Accessories",
      estimated_price: "$80"
    )
  end

  it "logs in and opens cart page" do
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: "Password@1"
    click_button "Log In"

    visit cart_path
    expect(page).to have_content("Cart")
  end
end
