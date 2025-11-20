class AiGiftSuggestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, except: :library
  before_action :set_event_recipient, only: :create
  before_action :set_ai_gift_suggestion, only: :toggle_wishlist

  def index
    @recipients = @event.recipients.order(:name)

    suggestions = @event.ai_gift_suggestions
                        .includes(:recipient)
                        .order(created_at: :desc)

    @suggestions_by_recipient = suggestions.group_by(&:recipient_id)
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
      redirect_to event_ai_gift_suggestions_path(@event, from: params[:from]), notice: message
    end
  end

  def library
    @events = current_user.events.order(:event_date, :event_name)

    @selected_event_id     = params[:event_id].presence
    @selected_recipient_id = params[:recipient_id].presence
    @selected_category     = params[:category].presence
    @saved_only            = params[:saved_only] == "1"
    @sort                  = params[:sort].presence || "newest"

    @recipients =
      if @selected_event_id
        Recipient.joins(:event_recipients)
                 .where(event_recipients: { user_id: current_user.id, event_id: @selected_event_id })
                 .distinct
                 .order(:name)
      else
        current_user.recipients.order(:name)
      end

    @suggestions = AiGiftSuggestion
                     .where(user: current_user)
                     .includes(:event, :recipient)

    @suggestions = @suggestions.where(event_id: @selected_event_id) if @selected_event_id
    @suggestions = @suggestions.where(recipient_id: @selected_recipient_id) if @selected_recipient_id
    @suggestions = @suggestions.where(category: @selected_category) if @selected_category
    @suggestions = @suggestions.where(saved_to_wishlist: true) if @saved_only

    @suggestions =
      case @sort
      when "oldest"
        @suggestions.order(created_at: :asc)
      else
        @suggestions.order(created_at: :desc)
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
