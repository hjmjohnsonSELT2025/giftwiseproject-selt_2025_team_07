# app/services/ai/prompt_builder.rb
require "json"

module Ai
  class PromptBuilder
    def initialize(user:, event:, recipient:, event_recipient:, past_gifts:, budget_cents:, previous_ai_titles: [])
      @user             = user
      @event            = event
      @recipient        = recipient
      @event_recipient  = event_recipient
      @past_gifts       = past_gifts
      @budget_cents     = budget_cents
      @previous_ai_titles = Array(previous_ai_titles).map { |t| safe(t) }.reject(&:blank?)
    end

    def build
      <<~PROMPT
        You are an AI gift recommendation assistant for an app called GiftWise.

        TASK:
        Suggest 5 thoughtful, realistic gift ideas for the recipient described below,
        for the specific event context, following ALL rules carefully.

        OUTPUT FORMAT:
        Return ONLY valid JSON in this exact shape (no extra text, no comments):

        {
          "gift_ideas": [
            {
              "title": "Short gift name",
              "description": "2–3 sentences explaining why it's a good fit.",
              "estimated_price": "human-friendly price range like '$20–$40'",
              "category": "category label like 'Tech', 'Books', 'Experience', 'Handmade', etc.",
              "special_notes": "optional notes about personalization or how to gift it"
            }
          ]
        }

        HARD RULES:
        - Never suggest anything that matches the recipient's dislikes.
        - Never repeat a past gift with the same or very similar name.
        - Never repeat or slightly rephrase any of the titles listed in "AI GIFT IDEAS ALREADY SUGGESTED".
        - Stay within the budget if one exists.
        - Suggest a variety of categories (not all from the same category).
        - Avoid generic, boring ideas; prefer something that feels personal to this recipient.

        USER CONTEXT:
        - GiftWise user: #{safe(@user.name)} (likes: #{safe(@user.likes)}, dislikes: #{safe(@user.dislikes)})

        EVENT CONTEXT:
        - Event name: #{safe(@event.event_name)}
        - Description: #{safe(@event.description)}
        - Date: #{@event.event_date}
        - Location: #{safe(@event.location)}
        - Event budget: #{format_money(@event.budget)}
        - Event-recipient allocated budget: #{format_money(@event_recipient.budget_allocated)}

        RECIPIENT PROFILE:
        - Name: #{safe(@recipient.name)}
        - Relationship: #{safe(@recipient.relationship)}
        - Age: #{@recipient.age}
        - Gender: #{safe(@recipient.gender)}
        - Occupation: #{safe(@recipient.occupation)}
        - Bio: #{safe(@recipient.bio)}
        - Hobbies: #{safe(@recipient.hobbies)}
        - Likes: #{safe(@recipient.likes)}
        - Favorite categories: #{safe(@recipient.favorite_categories)}
        - Dislikes: #{safe(@recipient.dislikes)}
        - Recipient budget: #{format_money(@recipient.budget)}

        EFFECTIVE BUDGET FOR THIS RECIPIENT:
        - #{effective_budget_text}

        PAST GIFTS TO AVOID REPEATING:
        #{past_gifts_section}

        AI GIFT IDEAS ALREADY SUGGESTED FOR THIS RECIPIENT + EVENT:
        These were generated previously by the AI. Do NOT repeat them, do NOT generate close variations, and do NOT change only a few words:
        #{previous_ai_titles_section}

        Please now return 5 gift ideas strictly as JSON using the schema above.
      PROMPT
    end

    private

    def safe(text)
      text.to_s.strip
    end

    def format_money(decimal)
      return "not specified" if decimal.nil?
      "$#{format('%.2f', decimal.to_f)}"
    end

    def effective_budget_text
      if @budget_cents.nil?
        "No strict budget, but keep suggestions reasonable and not too expensive."
      else
        dollars = (@budget_cents / 100.0)
        "Try to keep each gift roughly within $#{format('%.2f', dollars)} or a sensible range around it."
      end
    end

    def previous_ai_titles_section
      return "- No previous AI suggestions for this recipient/event yet." if @previous_ai_titles.blank?

      @previous_ai_titles.map { |t| "- #{t}" }.join("\n")
    end

    def past_gifts_section
      return "- No past gifts recorded for this recipient." if @past_gifts.blank?

      lines = @past_gifts.map do |g|
        "- #{safe(g.gift_name)} (#{format_money(g.price)} on #{g.given_on} · category: #{safe(g.category)})"
      end

      lines.join("\n")
    end
  end
end
