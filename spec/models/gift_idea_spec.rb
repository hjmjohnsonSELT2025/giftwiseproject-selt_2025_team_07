require "rails_helper"

RSpec.describe GiftIdea, type: :model do
  it "is valid with valid attributes" do
    event_recipient = create(:event_recipient)
    gift_idea = build(:gift_idea, event_recipient: event_recipient)

    expect(gift_idea).to be_valid
  end

  it "is invalid without idea" do
    event_recipient = create(:event_recipient)
    gift_idea = build(:gift_idea, idea: nil, event_recipient: event_recipient)

    expect(gift_idea).not_to be_valid
    expect(gift_idea.errors[:idea]).to include("can't be blank")
  end

  it "belongs to an event_recipient" do
    assoc = described_class.reflect_on_association(:event_recipient)
    expect(assoc.macro).to eq(:belongs_to)
  end
end
