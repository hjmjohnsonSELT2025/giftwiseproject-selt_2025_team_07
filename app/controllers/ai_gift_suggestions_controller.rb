class AiGiftSuggestionsController < ApplicationController
  # before_action :require_login
  before_action :set_event
  before_action :set_event_recipient, only: :create
  before_action :set_ai_gift_suggestion, only: :toggle_wishlist

  def index
    @recipients = @event.recipients.order(:name)

    suggestions = @event.ai_gift_suggestions
                        .includes(:recipient)
                        .order(created_at: :desc)

    @suggestions_by_recipient =
      suggestions.group_by(&:recipient_id)
  end

  def create
    suggester = Ai::GiftSuggester.new(
      user: current_user,
      event_recipient: @event_recipient
    )

    ideas = suggester.call(round_type: params[:round_type] || "initial")

    flash[:notice] = "Generated #{ideas.size} ideas for #{@event_recipient.recipient.name}."
    redirect_to event_ai_gift_suggestions_path(@event, from: params[:from])
  rescue Ai::GeminiClient::Error => e
    Rails.logger.error("Gemini error: #{e.message}")
    flash[:alert] = "Sorry, we couldn't generate ideas right now. Please try again later."
    redirect_to event_ai_gift_suggestions_path(@event, from: params[:from])
  end

  def toggle_wishlist
    @ai_gift_suggestion.update!(saved_to_wishlist: !@ai_gift_suggestion.saved_to_wishlist)

    message =
      if @ai_gift_suggestion.saved_to_wishlist?
        "Added “#{@ai_gift_suggestion.title}” to your wishlist."
      else
        "Removed “#{@ai_gift_suggestion.title}” from your wishlist."
      end

    case params[:from]
    when "wishlist"
      redirect_to wishlists_path, notice: message
    else
      # default: stay on AI ideas for this event
      redirect_to event_ai_gift_suggestions_path(@event, from: params[:from]), notice: message
    end
  end

  private

  def set_event
    @event = current_user.events.find(params[:event_id])
  end

  def set_event_recipient
    @event_recipient =
      EventRecipient.find_by!(user: current_user,
                              event_id: @event.id,
                              recipient_id: params[:recipient_id])
  end

  def set_ai_gift_suggestion
    @ai_gift_suggestion =
      @event.ai_gift_suggestions.find(params[:id])
  end
end