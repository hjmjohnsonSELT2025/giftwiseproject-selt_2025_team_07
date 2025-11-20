require "rails_helper"

RSpec.describe "Gift Ideas UI", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:user) { create(:user, password: "Password@123") }

  # Recipient that has an event → Gift Idea link should be enabled
  let!(:recipient_with_event) { create(:recipient, user: user) }
  let!(:event_recipient) do
    create(
      :event_recipient,
      user: user,
      recipient: recipient_with_event,
      event: create(:event, user: user)
    )
  end

  # Recipient without event → Gift Idea button should be disabled
  let!(:recipient_without_event) { create(:recipient, user: user, name: "No Event Recipient") }

  def login_as(user)
    visit "/login"  # adjust if your login path is different

    # These field labels come from your Cucumber-style steps ("Email", "Password").
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password@123"

    # Be robust about the submit button: click the first submit input or button
    submit = first("input[type='submit']", minimum: 0) || first("button[type='submit']", minimum: 0)
    raise "No submit button found on login page" unless submit

    submit.click
  end

  it "adds a gift idea successfully" do
    login_as(user)

    visit new_recipient_gift_idea_path(recipient_with_event)

    expect(page).to have_content("Add Gift Idea")

    fill_in "Gift Idea", with: "Laptop"
    fill_in "Description", with: "Gaming laptop"
    fill_in "Estimated Price", with: "1000"
    fill_in "Link", with: "https://amazon.com"

    click_button "Save"

    # Your controller currently redirects to /recipients
    expect(page).to have_current_path(
                      recipient_path(Recipient.first),
                      ignore_query: true
                    )
    expect(page).to have_content("Gift idea added successfully.")
  end

  it "cancels gift idea creation" do
    login_as(user)

    visit new_recipient_gift_idea_path(recipient_with_event)

    click_link "Cancel"

    # Cancel link in your view goes to recipients_path
    expect(page).to have_current_path(recipients_path)
  end

  it "keeps user on the form when idea is blank (validation error)" do
    login_as(user)

    visit new_recipient_gift_idea_path(recipient_with_event)

    # Do not fill in idea
    click_button "Save"

    # We stay on the Add Gift Idea page (URL remains the create path after render)
    expect(page).to have_content("Add Gift Idea")
    expect(page).to have_current_path(recipient_gift_ideas_path(recipient_with_event))

    # And no new record created
    expect(GiftIdea.count).to eq(0)
  end


  it "shows disabled Gift Idea button for recipients without events" do
    login_as(user)

    visit recipients_path

    # There should be at least one disabled Gift Idea button somewhere:
    expect(page).to have_selector("button[disabled]", text: "Gift Idea")
  end
end
