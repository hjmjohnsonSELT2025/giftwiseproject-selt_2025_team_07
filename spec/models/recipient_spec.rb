require "rails_helper"

RSpec.describe Recipient, type: :model do
  let(:user) { User.create!(name: "Test User", email: "user@mail.com", password: "Password1!") }

  it "is valid with valid attributes" do
    rec = user.recipients.new(name: "John")
    expect(rec).to be_valid
  end

  it "requires a name" do
    rec = user.recipients.new(name: nil)
    expect(rec).not_to be_valid
    expect(rec.errors[:name]).to be_present
  end

  it "validates age as integer when provided" do
    rec = user.recipients.new(name: "A", age: "abc")
    expect(rec).not_to be_valid
    expect(rec.errors[:age]).to be_present
  end

  it "accepts valid relationship" do
    rec = user.recipients.new(name: "A", relationship: Recipient::RELATIONSHIPS.first)
    expect(rec).to be_valid
  end

  it "rejects invalid relationship" do
    rec = user.recipients.new(name: "A", relationship: "Alien")
    expect(rec).not_to be_valid
  end

  it "belongs to a user" do
    rec = user.recipients.create!(name: "Ayra")
    expect(rec.user).to eq(user)
  end

  it "can be associated with events through event_recipients" do
    event = user.events.create!(event_name: "Birthday", event_date: Date.today + 1)
    rec   = user.recipients.create!(name: "Ayra")
    EventRecipient.create!(user: user, event: event, recipient: rec)

    expect(rec.events).to include(event)
  end

  it "#events_with_details returns event_recipients with events eager loaded" do
    event = user.events.create!(event_name: "Party", event_date: Date.today + 2)
    rec   = user.recipients.create!(name: "Myra")
    er    = EventRecipient.create!(user: user, event: event, recipient: rec)

    result = rec.events_with_details

    expect(result).to include(er)
    # ensure it responds to event (eager loaded association)
    expect(result.first.event).to eq(event)
  end
end
