require "rails_helper"

RSpec.describe Event, type: :model do
  let(:user) do
    User.create!(
      name:  "Test User",
      email: "user@example.com",
      password: "password"
    )
  end

  describe "scopes" do
    let!(:future_event_1) do
      Event.create!(
        user: user,
        event_name: "Soon",
        event_date: Date.today + 5,
        budget: 10
      )
    end

    let!(:future_event_2) do
      Event.create!(
        user: user,
        event_name: "Later",
        event_date: Date.today + 10,
        budget: 20
      )
    end

    let!(:past_event) do
      event = Event.new(
        user: user,
        event_name: "Past",
        event_date: Date.today - 1,
        budget: 5
      )
      event.save!(validate: false)  # allow past date in this test
      event
    end


    it "returns only future events in upcoming, ordered ascending" do
      result = Event.upcoming

      expect(result).to contain_exactly(future_event_1, future_event_2)
      expect(result.first).to eq(future_event_1)
    end

    it "returns only past events in past, ordered descending" do
      result = Event.past

      expect(result).to contain_exactly(past_event)
      expect(result.first).to eq(past_event)
    end
  end

  describe "#days_until" do
    it "returns number of days until event_date" do
      event = Event.new(
        user: user,
        event_name: "Test",
        event_date: Date.today + 7
      )

      expect(event.days_until).to eq 7
    end

    it "returns nil when event_date is nil" do
      event = Event.new(
        user: user,
        event_name: "No Date",
        event_date: nil
      )

      expect(event.days_until).to be_nil
    end
  end
end
