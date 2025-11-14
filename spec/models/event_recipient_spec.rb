# spec/models/event_recipient_spec.rb
require 'rails_helper'

RSpec.describe EventRecipient, type: :model do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
  end

  let(:event) do
    Event.create!(
      user: user,
      event_name: "Test Event",
      event_date: Date.tomorrow
    )
  end

  let(:recipient) do
    Recipient.create!(
      user: user,
      name: "John Doe",
      age: 30,
      relationship: "Friend"
    )
  end

  describe "associations" do
    it { should belong_to(:event) }
    it { should belong_to(:recipient) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject do
      EventRecipient.new(
        event: event,
        recipient: recipient,
        user: user
      )
    end

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without an event_id" do
      subject.event = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:event_id]).to include("can't be blank")
    end

    it "is invalid without a recipient_id" do
      subject.recipient = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:recipient_id]).to include("can't be blank")
    end

    it "is invalid without a user_id" do
      subject.user = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:user_id]).to include("can't be blank")
    end
  end

  describe "database constraints" do
    it "prevents duplicate event-recipient combinations" do
      EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user
      )

      duplicate = EventRecipient.new(
        event: event,
        recipient: recipient,
        user: user
      )

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "creation" do
    it "successfully creates a valid event_recipient" do
      event_recipient = EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user
      )

      expect(event_recipient).to be_persisted
      expect(event_recipient.event).to eq(event)
      expect(event_recipient.recipient).to eq(recipient)
      expect(event_recipient.user).to eq(user)
    end

    it "can store gift_ideas and budget_allocated" do
      event_recipient = EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user,
        gift_ideas: "Book about gardening",
        budget_allocated: 50.00
      )

      expect(event_recipient.gift_ideas).to eq("Book about gardening")
      expect(event_recipient.budget_allocated).to eq(50.00)
    end

    it "has a default gift_status of 'planning'" do
      event_recipient = EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user
      )

      expect(event_recipient.gift_status).to eq('planning')
    end
  end

  describe "deletion" do
    it "is deleted when the event is deleted" do
      event_recipient = EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user
      )

      expect { event.destroy }.to change(EventRecipient, :count).by(-1)
    end

    it "is deleted when the recipient is deleted" do
      event_recipient = EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user
      )

      expect { recipient.destroy }.to change(EventRecipient, :count).by(-1)
    end

    it "is deleted when the user is deleted" do
      event_recipient = EventRecipient.create!(
        event: event,
        recipient: recipient,
        user: user
      )

      expect { user.destroy }.to change(EventRecipient, :count).by(-1)
    end
  end
end