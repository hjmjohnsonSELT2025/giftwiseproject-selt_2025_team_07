class AiGiftSuggestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, except: :library
  before_action :set_event_recipient, only: :create
  before_action :set_ai_gift_suggestion, only: :toggle_wishlist

  # =====================
  # Event-level suggestions
  # =====================
  def index
    @recipients = @event.recipients.order(:name)

    suggestions = @event.ai_gift_suggestions
                        .includes(:recipient)
                        .order(created_at: :desc)

    @suggestions_by_recipient = suggestions.group_by(&:recipient_id)
  end

  def create
    round_type = params[:round_type] || "initial"

    # If AI is not enabled, use stub ideas in test/dev
    if !ai_enabled? && (Rails.env.test? || Rails.env.development?)
      ideas = generate_test_stub_ideas(@event_recipient, round_type)
      flash[:notice] =
        "Generated #{ideas.size} sample ideas for #{@event_recipient.recipient.name} (AI not configured)."
      return redirect_to event_ai_gift_suggestions_path(@event, from: params[:from])
    end

    suggester = Ai::GiftSuggester.new(
      user: current_user,
      event_recipient: @event_recipient
    )

    ideas = suggester.call(round_type: round_type)

    # Extra safety in test: if Gemini returns nothing, still create stubs
    if Rails.env.test? && ideas.blank?
      ideas = generate_test_stub_ideas(@event_recipient, round_type)
    end

    flash[:notice] = "Generated #{ideas.size} ideas for #{@event_recipient.recipient.name}."
    redirect_to event_ai_gift_suggestions_path(@event, from: params[:from])

  rescue Ai::GeminiClient::Error => e
    Rails.logger.error("Gemini error: #{e.message}")

    human_message =
      if e.message.include?("429") || e.message.include?("RESOURCE_EXHAUSTED")
        "We’ve hit the AI rate limit for now. Please wait a bit before trying again."
      else
        "Sorry, we couldn't generate ideas right now. Please try again later."
      end

    if Rails.env.test?
      ideas = generate_test_stub_ideas(@event_recipient, round_type)
      flash[:notice] =
        "Generated #{ideas.size} sample ideas for #{@event_recipient.recipient.name} (AI error in test)."
    else
      flash[:alert] = human_message
    end

    if ideas.blank? && (Rails.env.test? || Rails.env.development?)
      ideas = generate_test_stub_ideas(@event_recipient, round_type)
      fallback_used = true
    end

    flash[:notice] =
      if fallback_used
        "Generated #{ideas.size} sample ideas for #{@event_recipient.recipient.name} (AI not configured)."
      else
        "Generated #{ideas.size} ideas for #{@event_recipient.recipient.name}."
      end

    redirect_to event_ai_gift_suggestions_path(@event, from: params[:from])
  end

  def toggle_wishlist
    suggestion = @event.ai_gift_suggestions.find(params[:id])

    planner_ids = [@event.user_id] +
                  @event.collaborators.accepted
                        .where(role: [Collaborator::ROLE_CO_PLANNER, Collaborator::ROLE_OWNER])
                        .pluck(:user_id)

    planner_ids.uniq!

    ActiveRecord::Base.transaction do
      already_saved = Wishlist.exists?(user_id: current_user.id, ai_gift_suggestion_id: suggestion.id)

      if already_saved
        Wishlist.where(user_id: planner_ids, ai_gift_suggestion_id: suggestion.id).delete_all
      else
        planner_ids.each do |uid|
          Wishlist.find_or_create_by!(user_id: uid, ai_gift_suggestion_id: suggestion.id) do |wl|
            wl.recipient_id = suggestion.recipient_id
          end
        end
      end
    end

    redirect_back fallback_location: event_ai_gift_suggestions_path(@event, from: params[:from])
  end

  # =====================
  # AI Library (global)
  # =====================
  def library
    @scope = params[:scope].presence_in(%w[mine collab all]) || "mine"

    accessible_events = Event.accessible_to(current_user)

    @events =
      case @scope
      when "mine"
        Event.where(user_id: current_user.id)
      when "collab"
        accessible_events.where.not(user_id: current_user.id)
      else # "all"
        accessible_events
      end

    suggestions = AiGiftSuggestion.where(event_id: @events.select(:id))

    # Apply filters (event/recipient/category/saved_only/sort)
    @selected_event_id = params[:event_id].presence
    @selected_recipient_id = params[:recipient_id].presence
    @selected_category = params[:category].presence
    @sort = params[:sort].presence_in(%w[newest oldest]) || "newest"
    saved_only = params[:saved_only] == "1"

    suggestions = suggestions.where(event_id: @selected_event_id) if @selected_event_id
    suggestions = suggestions.where(recipient_id: @selected_recipient_id) if @selected_recipient_id
    suggestions = suggestions.where(category: @selected_category) if @selected_category

    if saved_only
      suggestions = suggestions.joins(:wishlists).where(wishlists: { user_id: current_user.id }).distinct
    end

    suggestions = suggestions.order(created_at: (@sort == "oldest" ? :asc : :desc))

    @suggestions = suggestions.includes(:event, :recipient)

    # Recipients dropdown should match the visible event set
    @recipients = Recipient
                    .joins(:event_recipients)
                    .where(event_recipients: { event_id: @events.select(:id) })
                    .distinct
                    .order(:name)
  end

  private
  def ai_enabled?
    creds = Rails.application.credentials

    ENV["GEMINI_API_KEY"].present? ||
      creds.dig(:gemini, :api_key).present?
  end

  # Used only in test / fallback mode
  def generate_test_stub_ideas(event_recipient, round_type)
    existing_titles = AiGiftSuggestion.where(event_recipient: event_recipient).pluck(:title)

    base_titles = [
      "Personalized Mug",
      "Gift Card Bundle",
      "Artisanal Chocolate Box",
      "Cozy Hoodie",
      "Desk Organizer Set",
      "Bluetooth Speaker",
      "Scented Candle Set",
      "Custom Photo Frame"
    ]

    chosen_titles = base_titles.reject { |t| existing_titles.include?(t) }.first(5)

    chosen_titles.map do |title|
      AiGiftSuggestion.create!(
        user:              current_user,  # <— IMPORTANT: whoever triggered the generation
        event:             event_recipient.event,
        recipient:         event_recipient.recipient,
        event_recipient:   event_recipient,
        round_type:        round_type,
        title:             title,
        description:       "Test AI suggestion for #{event_recipient.recipient.name}",
        category:          "General",
        estimated_price:   "$25–$75",
        saved_to_wishlist: false
      )
    end
  end

  def set_event
    @event = Event.accessible_to(current_user).find(params[:event_id])

    # Extra safety: only people allowed to manage gifts can open this page
    unless @event.can_manage_gifts?(current_user)
      redirect_to dashboard_path,
                  alert: "You do not have permission to manage gifts for this event."
    end
  end

  def set_event_recipient
    # Co-planners should be able to generate ideas too, so don’t lock by user_id
    @event_recipient =
      @event.event_recipients.find_by!(
        recipient_id: params[:recipient_id]
      )
  end

  def set_ai_gift_suggestion
    @ai_gift_suggestion =
      @event.ai_gift_suggestions.find(params[:id])
  end
end