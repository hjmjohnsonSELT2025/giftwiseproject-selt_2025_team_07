require "rails_helper"

RSpec.describe Ai::GiftSuggester do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "Password1!"
    )
  end

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

  let(:fake_gemini_client)   { instance_double(Ai::GeminiClient) }
  let(:fake_unsplash_client) { instance_double(UnsplashClient) }

  subject(:suggester) do
    described_class.new(
      user: user,
      event_recipient: event_recipient,
      gemini_client: fake_gemini_client,
      unsplash_client: fake_unsplash_client
    )
  end

  before do
    # we don't care about real images in these tests
    allow(fake_unsplash_client).to receive(:search_image).and_return("https://example.com/image.jpg")
  end

  context "when Gemini returns normal unique ideas" do
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

    before do
      allow(fake_gemini_client).to receive(:generate_gift_ideas).and_return(idea_hashes)
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

    it "passes a prompt string to the Gemini client" do
      suggester.call
      expect(fake_gemini_client).to have_received(:generate_gift_ideas).with(a_kind_of(String))
    end

    it "uses Unsplash to fetch an image per idea" do
      suggester.call
      expect(fake_unsplash_client).to have_received(:search_image).at_least(:once)
    end
  end

  context "when Gemini returns titles that already exist for this event_recipient" do
    let(:idea_hashes) do
      [
        {
          "title" => "Cozy Blanket",
          "description" => "duplicate 1",
          "estimated_price" => "$20–$40",
          "category" => "Home",
          "special_notes" => nil
        },
        {
          "title" => "wireless MOUSE", # duplicate with different case
          "description" => "duplicate 2",
          "estimated_price" => "$40–$60",
          "category" => "Tech",
          "special_notes" => nil
        },
        {
          "title" => "Personalized Mug",
          "description" => "new idea",
          "estimated_price" => "$10–$20",
          "category" => "Personalized",
          "special_notes" => "Add her name"
        }
      ]
    end

    before do
      # existing DB suggestions for this event_recipient
      AiGiftSuggestion.create!(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        round_type: "initial",
        title: "Cozy Blanket"
      )

      AiGiftSuggestion.create!(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        round_type: "initial",
        title: "Wireless Mouse"
      )

      allow(fake_gemini_client).to receive(:generate_gift_ideas).and_return(idea_hashes)
    end

    it "does not create new suggestions for titles that already exist (case-insensitive)" do
      expect {
        suggester.call(round_type: "regenerate")
      }.to change(AiGiftSuggestion, :count).by(1) # only Personalized Mug is new

      titles = AiGiftSuggestion.where(event_recipient: event_recipient).pluck(:title)

      expect(titles).to include("Cozy Blanket", "Wireless Mouse", "Personalized Mug")
      # ensure we didn't create extra copies of existing titles
      expect(titles.count("Cozy Blanket")).to eq(1)
      expect(titles.count("Wireless Mouse")).to eq(1)
    end
  end

  context "when Gemini returns duplicate titles within the same batch" do
    let(:idea_hashes) do
      [
        {
          "title" => "Spa Day",
          "description" => "first version",
          "estimated_price" => "$80–$120",
          "category" => "Experience",
          "special_notes" => nil
        },
        {
          "title" => "spa day", # same title with different case in same batch
          "description" => "duplicate version",
          "estimated_price" => "$80–$120",
          "category" => "Experience",
          "special_notes" => nil
        },
        {
          "title" => "Board Game Night",
          "description" => "Game night set",
          "estimated_price" => "$30–$60",
          "category" => "Games",
          "special_notes" => nil
        }
      ]
    end

    before do
      allow(fake_gemini_client).to receive(:generate_gift_ideas).and_return(idea_hashes)
    end

    it "only creates unique suggestions from the batch (filters duplicates by title)" do
      expect {
        suggester.call(round_type: "initial")
      }.to change(AiGiftSuggestion, :count).by(2)

      titles = AiGiftSuggestion.where(event_recipient: event_recipient).pluck(:title)

      # Only one Spa Day should exist (case-insensitive)
      expect(titles.count { |t| t.downcase == "spa day" }).to eq(1)
      expect(titles).to include("Board Game Night")
    end
  end
end
