require "rails_helper"

RSpec.describe Ai::GiftSuggester do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "Password1!") }
  let(:event) do
    user.events.create!(
      event_name: "Birthday",
      event_date: Date.today + 7.days,
      budget: 120
    )
  end
  let(:recipient) do
    user.recipients.create!(
      name: "Mom",
      relationship: "Mother",
      age: 55,
      hobbies: "Reading, gardening",
      likes: "Books, plants",
      dislikes: "Perfume"
    )
  end
  let(:event_recipient) do
    EventRecipient.create!(
      user: user,
      event: event,
      recipient: recipient,
      budget_allocated: 60
    )
  end

  let(:fake_gemini_client) { instance_double(Ai::GeminiClient) }
  let(:fake_unsplash_client) { instance_double(UnsplashClient) }

  let(:idea_hashes) do
    [
      {
        "title" => "Gardening Tool Set",
        "description" => "A nice set of tools for her garden.",
        "estimated_price" => "$30–$50",
        "category" => "Gardening",
        "special_notes" => "Choose ergonomic handles."
      },
      {
        "title" => "Hardcover Novel",
        "description" => "A best-selling book she might enjoy.",
        "estimated_price" => "$15–$25",
        "category" => "Books",
        "special_notes" => "Pick a genre she likes."
      }
    ]
  end

  subject(:suggester) do
    described_class.new(
      user: user,
      event_recipient: event_recipient,
      gemini_client: fake_gemini_client,
      unsplash_client: fake_unsplash_client
    )
  end

  before do
    allow(fake_gemini_client).to receive(:generate_gift_ideas).and_return(idea_hashes)
    allow(fake_unsplash_client).to receive(:search_image).and_return("https://example.com/image.jpg")
  end

  it "creates AiGiftSuggestion records for the returned ideas" do
    expect {
      suggester.call(round_type: "initial")
    }.to change(AiGiftSuggestion, :count).by(2)

    suggestion = AiGiftSuggestion.last
    expect(suggestion.user).to eq(user)
    expect(suggestion.event).to eq(event)
    expect(suggestion.recipient).to eq(recipient)
    expect(suggestion.event_recipient).to eq(event_recipient)
    expect(suggestion.round_type).to eq("initial")
    expect(suggestion.title).to eq("Hardcover Novel")
    expect(suggestion.image_url).to eq("https://example.com/image.jpg")
  end

  it "passes a prompt to Gemini client" do
    suggester.call
    expect(fake_gemini_client).to have_received(:generate_gift_ideas).with(a_kind_of(String))
  end

  it "uses Unsplash to fetch an image per idea" do
    suggester.call
    expect(fake_unsplash_client).to have_received(:search_image).at_least(:once)
  end
end
