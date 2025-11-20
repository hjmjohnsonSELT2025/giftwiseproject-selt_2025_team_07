require "rails_helper"

RSpec.describe Ai::PromptBuilder do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "Password1!"
    )
  end

  let(:event) do
    user.events.create!(
      event_name: "Birthday Party",
      event_date: Date.today + 7.days,
      budget: 100
    )
  end

  let(:recipient) do
    user.recipients.create!(
      name:         "Alex",
      relationship: "Friend",
      age:          25,
      hobbies:      "Music",
      likes:        "Headphones, concerts",
      dislikes:     "Perfume"
    )
  end

  let(:event_recipient) do
    EventRecipient.create!(
      user: user,
      event: event,
      recipient: recipient,
      budget_allocated: 50
    )
  end

  let(:past_gifts)   { [] }
  let(:budget_cents) { nil }

  it "includes previous AI titles in the 'AI GIFT IDEAS ALREADY SUGGESTED' section when provided" do
    previous_titles = ["Cozy Blanket", "Wireless Mouse"]

    prompt = described_class.new(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      past_gifts: past_gifts,
      budget_cents: budget_cents,
      previous_ai_titles: previous_titles
    ).build

    expect(prompt).to include("AI GIFT IDEAS ALREADY SUGGESTED FOR THIS RECIPIENT + EVENT")
    expect(prompt).to include("Cozy Blanket")
    expect(prompt).to include("Wireless Mouse")
    expect(prompt).to include("Do NOT repeat them, do NOT generate close variations")
  end

  it "mentions there are no previous AI suggestions when previous_ai_titles is empty" do
    prompt = described_class.new(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      past_gifts: past_gifts,
      budget_cents: budget_cents,
      previous_ai_titles: []
    ).build

    expect(prompt).to include("No previous AI suggestions for this recipient/event yet.")
  end
end
