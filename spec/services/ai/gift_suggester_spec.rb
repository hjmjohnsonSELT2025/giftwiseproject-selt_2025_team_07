require "rails_helper"

RSpec.describe Ai::GiftSuggester do
  let(:user) do
    User.create!(
      name: "Tester",
      email: "tester@example.com",
      password: "Password@123"
    )
  end

  let(:event) do
    Event.create!(user: user, event_name: "Birthday", event_date: Date.today)
  end

  let(:recipient) do
    Recipient.create!(name: "Sam", relationship: "Friend", user: user)
  end

  let(:event_recipient) do
    EventRecipient.create!(user: user, event: event, recipient: recipient)
  end

  let(:fake_gemini) { instance_double("Ai::GeminiClient") }
  let(:fake_unsplash) { instance_double("UnsplashClient") }

  subject(:suggester) do
    described_class.new(
      user: user,
      event_recipient: event_recipient,
      gemini_client: fake_gemini,
      unsplash_client: fake_unsplash
    )
  end

  # -------------------------------------------------------------
  # 1. Test compute_effective_budget_cents (all branches)
  # -------------------------------------------------------------
  describe "#call — budget logic" do
    before { allow(fake_unsplash).to receive(:search_image).and_return(nil) }

    it "uses recipient.budget first" do
      recipient.update!(budget: 50.0)

      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "Gift", "description" => "d" }
                                                                     ])

      suggester.call
      expect(suggester.send(:compute_effective_budget_cents)).to eq(5000)
    end

    it "uses event_recipient.budget_allocated second" do
      event_recipient.update!(budget_allocated: 30.0)

      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "Gift", "description" => "d" }
                                                                     ])

      suggester.call
      expect(suggester.send(:compute_effective_budget_cents)).to eq(3000)
    end

    it "uses event.budget divided by recipients when present" do
      event.update!(budget: 100.0)

      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "Gift", "description" => "d" }
                                                                     ])

      suggester.call
      expect(suggester.send(:compute_effective_budget_cents)).to eq(10000)
    end

    it "returns nil when no budget exists" do
      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([])

      suggester.call
      expect(suggester.send(:compute_effective_budget_cents)).to eq(nil)
    end
  end

  # -------------------------------------------------------------
  # 2. Test duplicate title rejection & blank skipping
  # -------------------------------------------------------------
  describe "#call — duplicate & blank title handling" do
    before do
      allow(fake_unsplash).to receive(:search_image).and_return("img.jpg")
    end

    it "skips blank titles and removes duplicates" do
      existing = AiGiftSuggestion.create!(
        user: user, event: event, recipient: recipient,
        event_recipient: event_recipient,
        title: "Existing", description: "d"
      )

      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "  ", "description" => "Blank" },
                                                                       { "title" => "Existing", "description" => "dup" },
                                                                       { "title" => "existing ", "description" => "dup2" }, # case-insensitive duplicate
                                                                       { "title" => "Unique", "description" => "OK" }
                                                                     ])

      results = suggester.call

      expect(results.size).to eq(1)
      expect(results.first.title).to eq("Unique")
    end

    it "skips duplicates within the same batch" do
      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "Mug", "description" => "1" },
                                                                       { "title" => "mug ", "description" => "2" }, # duplicate
                                                                       { "title" => "MUG", "description" => "3" }   # duplicate
                                                                     ])

      results = suggester.call

      expect(results.size).to eq(1)
      expect(results.first.title).to eq("Mug")
    end
  end

  # -------------------------------------------------------------
  # 3. Test safe_fetch_image_url error handling
  # -------------------------------------------------------------
  describe "#safe_fetch_image_url" do
    it "returns nil when UnsplashClient::Error is raised" do
      allow(fake_unsplash).to receive(:search_image)
                                .and_raise(UnsplashClient::Error.new("bad"))

      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "Gift", "description" => "d" }
                                                                     ])

      result = suggester.call.first
      expect(result.image_url).to eq(nil)
    end

    it "returns nil when StandardError is raised" do
      allow(fake_unsplash).to receive(:search_image)
                                .and_raise(StandardError.new("boom"))

      allow(fake_gemini).to receive(:generate_gift_ideas).and_return([
                                                                       { "title" => "Gift", "description" => "d" }
                                                                     ])

      result = suggester.call.first
      expect(result.image_url).to eq(nil)
    end
  end
end
