# app/services/ai/gift_suggester.rb
module Ai
  class GiftSuggester
    def initialize(user:, event_recipient:, gemini_client: nil, unsplash_client: nil)
      @user = user
      @event_recipient = event_recipient
      @event = event_recipient.event
      @recipient = event_recipient.recipient

      @gemini_client   = gemini_client   || Ai::GeminiClient.new
      @unsplash_client = unsplash_client || ::UnsplashClient.new
    end

    # round_type: "initial" or "regenerate"
    # Returns an array of AiGiftSuggestion records
    def call(round_type: "initial")
      budget_cents = compute_effective_budget_cents

      past_gifts = GiftGivenBacklog.where(
        user_id: @user.id,
        recipient_id: @recipient.id
      ).order(given_on: :desc)

      prompt = Ai::PromptBuilder.new(
        user: @user,
        event: @event,
        recipient: @recipient,
        event_recipient: @event_recipient,
        past_gifts: past_gifts,
        budget_cents: budget_cents
      ).build

      idea_hashes = @gemini_client.generate_gift_ideas(prompt)

      suggestions = []

      AiGiftSuggestion.transaction do
        idea_hashes.each do |idea|
          title = idea["title"].to_s.strip
          next if title.blank? # skip bad entries

          # Because your current Gemini prompt returns only title/description,
          # these might be nil for now — that's okay.
          description      = idea["description"]
          estimated_price  = idea["estimated_price"]
          category         = idea["category"]
          special_notes    = idea["special_notes"]

          query = [title, category, "gift"].compact.join(" ")
          image_url = safe_fetch_image_url(query)

          suggestions << AiGiftSuggestion.create!(
            user: @user,
            event: @event,
            recipient: @recipient,
            event_recipient: @event_recipient,
            round_type: round_type,
            title: title,
            description: description,
            estimated_price: estimated_price,
            category: category,
            special_notes: special_notes,
            image_url: image_url
          )
        end
      end

      suggestions
    end

    private

    # Priority:
    # 1. recipient.budget
    # 2. event_recipient.budget_allocated
    # 3. event.budget / recipient_count
    # Returns integer cents or nil
    def compute_effective_budget_cents
      if @recipient.budget.present?
        return decimal_to_cents(@recipient.budget)
      end

      if @event_recipient.budget_allocated.present?
        return decimal_to_cents(@event_recipient.budget_allocated)
      end

      if @event.budget.present?
        count = @event.recipients.count
        return nil if count.zero?

        per_recipient = @event.budget.to_f / count
        return (per_recipient * 100).to_i
      end

      nil
    end

    def decimal_to_cents(decimal)
      (decimal.to_f * 100).to_i
    end

    def safe_fetch_image_url(query)
      @unsplash_client.search_image(query)
    rescue ::UnsplashClient::Error => e
      Rails.logger.warn "[Unsplash] #{e.class}: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.warn "[Unsplash] unexpected error: #{e.class} #{e.message}"
      nil
    end
  end
end
