class AiGiftSuggestionsController < ApplicationController
  before_action :authenticate_user!   # adjust to your auth method
  before_action :set_event

  def index
    @recipients = @event.recipients
                        .where(user_id: current_user.id)
                        .includes(:event_recipients)

    @suggestions_by_recipient =
      AiGiftSuggestion
        .where(user: current_user, event: @event)
        .includes(:recipient)
        .order(created_at: :desc)
        .group_by(&:recipient_id)
  end

  def create
    recipient = @event.recipients.where(user_id: current_user.id).find(params[:recipient_id])

    event_recipient = EventRecipient.find_by!(
      user_id: current_user.id,
      event_id: @event.id,
      recipient_id: recipient.id
    )

    round_type = params[:round_type] || "initial"

    suggestions = Ai::GiftSuggester.new(
      user: current_user,
      event_recipient: event_recipient
    ).call(round_type: round_type)

    redirect_to event_ai_gift_suggestions_path(@event),
                notice: "Generated #{suggestions.size} ideas for #{recipient.name}."
  rescue => e
    Rails.logger.error "[AI Gift Suggestions] #{e.class}: #{e.message}"
    redirect_to event_ai_gift_suggestions_path(@event),
                alert: "Something went wrong while generating ideas. Please try again."
  end

  private

  def set_event
    @event = current_user.events.find(params[:event_id])
  end
end
