require "rails_helper"

RSpec.describe Recipient, type: :model do
  let(:user) { User.create!(name: "Test User", email: "user@mail.com", password: "password123") }

  it "is valid with valid attributes" do
    rec = user.recipients.new(name: "John")
    expect(rec).to be_valid
  end

  it "requires a name" do
    rec = user.recipients.new(name: nil)
    expect(rec).not_to be_valid
  end

  it "validates age as integer" do
    rec = user.recipients.new(name: "A", age: "abc")
    expect(rec).not_to be_valid
  end

  it "accepts valid relationship" do
    rec = user.recipients.new(name: "A", relationship: "Friend")
    expect(rec).to be_valid
  end

  it "rejects invalid relationship" do
    rec = user.recipients.new(name: "A", relationship: "Alien")
    expect(rec).not_to be_valid
  end
end