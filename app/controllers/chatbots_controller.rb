class ChatbotsController < ApplicationController
  before_action :authenticate_user!

  # Renders the sidebar widget (mounted from dashboard)
  def widget
    session[:chatbot_history] ||= []

    if session[:chatbot_history].empty?
      push_message("bot", welcome_text)
    end

    render :widget
  end

  # AJAX endpoint the Stimulus controller calls
  def message
    text   = params[:message].to_s.strip
    intent = params[:intent].presence

    session[:chatbot_history] ||= []

    # Store user message if they typed something
    push_message("user", text) if text.present?

    close_panel = false
    bot_text    = nil
    replies     = []

    case intent
      # -------- reload / reset chat (keep panel open) --------
    when "reset_session", "reload_chat"
      session[:chatbot_history] = []
      bot_text = welcome_text
      replies  = default_quick_replies

      # -------- exit chat: clear history + tell front-end to close --------
    when "exit_chat"
      session[:chatbot_history] = []
      bot_text    = "Okay, closing the assistant for now. Tap the chatbot icon again whenever you need help."
      replies     = []
      close_panel = true

    else
      bot_text, replies = handle_intent(intent, text)
    end

    # Store bot reply
    push_message("bot", bot_text) if bot_text.present?

    render json: {
      messages:      session[:chatbot_history],
      quick_replies: replies,
      close:         close_panel
    }
  end

  private

  # ---------- Core helpers ----------

  def welcome_text
    "Hi #{current_user.name.presence || 'there'} 👋\n" \
      "I can help you with events, budgets, recipients, wishlists and navigation inside GiftWise.\n" \
      "You can tap a suggestion below or type a question."
  end

  def push_message(role, text)
    return if text.blank?

    session[:chatbot_history] << {
      role: role,                      # "user" or "bot"
      text: text,
      at:   Time.current.strftime("%H:%M")
    }
  end

  # Decide what to do for each intent
  def handle_intent(intent, text)
    case
      # ---------- budgets ----------
    when intent == "upcoming_total_budget"
      [upcoming_total_budget_text, default_quick_replies]

    when intent == "per_event_budget"
      [per_event_budget_intro_text, per_event_budget_replies]

    when intent&.start_with?("event_budget_")
      event_budget_response(intent)

      # ---------- recipients ----------
    when intent == "recipients_summary"
      [recipients_summary_text, default_quick_replies]

      # ---------- navigation-related ----------
    when intent == "upcoming_events_brief"
      [upcoming_events_brief_text, default_quick_replies]

    when intent == "help_navigation"
      [help_navigation_text, navigation_quick_replies]

    when intent == "nav_add_event"
      [nav_add_event_text, navigation_quick_replies]

    when intent == "nav_add_recipient"
      [nav_add_recipient_text, navigation_quick_replies]

    when intent == "nav_add_recipient_to_event"
      [nav_add_recipient_to_event_text, navigation_quick_replies]

    when intent == "nav_view_wishlist"
      [nav_view_wishlist_text, navigation_quick_replies]

    when intent == "nav_edit_profile"
      [nav_edit_profile_text, navigation_quick_replies]

      # ---------- fallback ----------
    else
      [fallback_text(text, intent), default_quick_replies]
    end
  end

  # ---------- Quick replies ----------

  def default_quick_replies
    replies = [
      { label: "All upcoming events total budget",     intent: "upcoming_total_budget" },
      { label: "Budget for a specific upcoming event", intent: "per_event_budget" },
      { label: "Show upcoming events",                 intent: "upcoming_events_brief" },
      { label: "Show my recipients",                   intent: "recipients_summary" },
      { label: "Navigation help",                      intent: "help_navigation" },
      { label: "Exit chat / reset",                    intent: "reset_session" }
    ]

    # Hide event-related options if no upcoming events
    events_exist = current_user.events.where("event_date >= ?", Date.today).exists?
    unless events_exist
      replies.reject! do |r|
        %w[upcoming_total_budget per_event_budget upcoming_events_brief].include?(r[:intent])
      end
    end

    # Hide recipients option if none
    recipients_exist = current_user.recipients.exists?
    replies.reject! { |r| r[:intent] == "recipients_summary" } unless recipients_exist

    replies
  end

  # Navigation-specific quick replies (shown after a nav answer)
  def navigation_quick_replies
    [
      { label: "How do I add an event?",               intent: "nav_add_event" },
      { label: "How do I add a recipient?",            intent: "nav_add_recipient" },
      { label: "How do I link recipients to an event?",intent: "nav_add_recipient_to_event" },
      { label: "How do I see my wishlist?",            intent: "nav_view_wishlist" },
      { label: "How do I edit my profile/password?",   intent: "nav_edit_profile" },
      { label: "Back to main options",                 intent: "reset_session" }
    ]
  end

  # ---------- Budget: all upcoming events ----------

  def upcoming_total_budget_text
    events = current_user.events.where("event_date >= ?", Date.today)

    if events.empty?
      return "You don’t have any upcoming events yet. Add one from the dashboard to start tracking budgets."
    end

    total_budget = events.sum(:budget) || 0

    lines = []
    lines << "Here’s the planned budget for your upcoming events:\n"

    events.order(:event_date).each do |e|
      budget   = e.budget || 0
      date_str = e.event_date&.strftime("%b %d, %Y") || "no date"
      lines << "- #{e.event_name} on #{date_str}: $#{sprintf('%.2f', budget)}"
    end

    lines << ""
    lines << "Overall total across upcoming events: $#{sprintf('%.2f', total_budget)}"
    lines.join("\n")
  end

  # ---------- Budget: single event ----------

  def per_event_budget_intro_text
    events = current_user.events.where("event_date >= ?", Date.today)
    if events.empty?
      "You don’t have any upcoming events yet, so I can’t calculate a per-event budget. Add an event from the dashboard first."
    else
      "Pick one of your upcoming events below to see its total budget across all recipients."
    end
  end

  def per_event_budget_replies
    events = current_user.events
                         .where("event_date >= ?", Date.today)
                         .order(:event_date)
                         .limit(6)

    events.map do |e|
      {
        label:  "#{e.event_name} (#{e.event_date&.strftime('%b %d') || 'no date'})",
        intent: "event_budget_#{e.id}"
      }
    end
  end

  def event_budget_response(intent)
    event_id = intent.split("event_budget_").last.to_i
    event    = current_user.events.find_by(id: event_id)

    unless event
      return [
        "I couldn’t find that event. It may have been deleted or might not belong to your account.",
        default_quick_replies
      ]
    end

    rows            = EventRecipient.where(user_id: current_user.id, event_id: event.id)
    allocated_total = rows.sum(:budget_allocated) || 0
    event_budget    = event.budget || 0
    date_str        = event.event_date&.strftime("%b %d, %Y") || "no date"

    lines = []
    lines << "Budget details for “#{event.event_name}” (#{date_str}):"
    lines << ""

    if rows.exists?
      lines << "- Sum of per-recipient budgets: $#{sprintf('%.2f', allocated_total)}"
    else
      lines << "- No per-recipient budgets found in event–recipient allocations."
    end

    lines << "- Event-level budget: $#{sprintf('%.2f', event_budget)}"

    if allocated_total > 0
      diff = event_budget - allocated_total
      lines << ""
      lines << "Difference (event-level budget − per-recipient total): $#{sprintf('%.2f', diff)}"
    end

    [lines.join("\n"), default_quick_replies]
  end

  # ---------- Recipients summary ----------

  def recipients_summary_text
    recs = current_user.recipients.order(:name).limit(10)

    if recs.empty?
      return "You don’t have any recipients yet. Use the Recipients card on the dashboard to add someone you give gifts to."
    end

    total = current_user.recipients.count
    lines = ["Here are some of your recipients:\n"]

    recs.each do |r|
      line = "- #{r.name}"
      bits = []
      bits << r.relationship if r.relationship.present?
      bits << r.email if r.email.present?
      line << " (#{bits.join(' · ')})" if bits.any?
      lines << line
    end

    if total > recs.size
      lines << ""
      lines << "…and #{total - recs.size} more. You can see full details on the Recipients page."
    else
      lines << ""
      lines << "You can see full details and edit them on the Recipients page."
    end

    lines.join("\n")
  end

  # ---------- Other helpers ----------

  def upcoming_events_brief_text
    events = current_user.events
                         .where("event_date >= ?", Date.today)
                         .order(:event_date)
                         .limit(5)

    if events.empty?
      "You don’t have any upcoming events yet. Use the Events card on the dashboard to add your first one."
    else
      lines = ["Here are your next few events:\n"]
      events.each do |e|
        date_str          = e.event_date&.strftime("%b %d, %Y") || "no date"
        primary_recipient = e.recipients.first&.name
        label             = primary_recipient.present? ? "#{e.event_name} for #{primary_recipient}" : e.event_name
        lines << "- #{label} on #{date_str}"
      end
      lines.join("\n")
    end
  end

  def help_navigation_text
    <<~TEXT.strip
      Here are some common things I can help you with inside GiftWise:

      • How do I add an event?
      • How do I add a recipient?
      • How do I link recipients to an event?
      • How do I see my wishlist?
      • How do I edit my profile or password?

      You can tap any of these options below to see step-by-step instructions.
    TEXT
  end

  def nav_add_event_text
    <<~TEXT.strip
      Here’s how to add a new event:

      1. Go to the Dashboard (you’re probably already there after login).
      2. Click on the “Events” card, or use the “+ Add Event” button in the Upcoming Events section.
      3. On the “New Event” page:
         • Enter the event name (required).
         • Choose the event date.
         • Optionally add location, budget and description.
      4. Click “Create Event”.

      After creating it, you’ll see the event under “Upcoming Events” and in the Events list page.
    TEXT
  end

  def nav_add_recipient_text
    <<~TEXT.strip
      To add a new recipient (person you give gifts to):

      1. From the Dashboard, click on the “Recipients” card.
      2. On the Recipients page, click “New Recipient”.
      3. Fill in:
         • Name (required).
         • Email, relationship, age, hobbies, likes, dislikes, budget, etc. (optional).
      4. Click “Create Recipient”.

      The new recipient will appear in the recipients table and can be linked to events.
    TEXT
  end

  def nav_add_recipient_to_event_text
    <<~TEXT.strip
      To link recipients to an event:

      1. First make sure you have at least one Event and one Recipient created.
      2. Go to the Events page and click on an event you want to manage.
      3. On the event details page, look for the section where you can add or manage recipients
         (for example, checkboxes or an “Add recipient” button).
      4. Select the recipient(s) you want to attach to the event.
      5. Save/update the event.

      Once linked, you’ll see those recipients associated with that event, and the AI gift suggestions
      and budgets can use that information.
    TEXT
  end

  def nav_view_wishlist_text
    <<~TEXT.strip
      To see your wishlist:

      1. Look at the top-right of the app header.
      2. Click the heart icon (❤️) – that’s the Wishlist shortcut.
      3. You’ll be taken to the Wishlist page, where you can see items you’ve saved
         from AI gift suggestions or added manually.

      From there you can review ideas, prices and notes before buying gifts.
    TEXT
  end

  def nav_edit_profile_text
    <<~TEXT.strip
      To edit your profile or password:

      1. In the top-right corner of the app header, click your profile avatar (small circle).
      2. In the dropdown:
         • Click “Edit Profile” to update your name, email and other details.
         • Click “Change password” to update your password.
      3. Make your changes and click the Save/Update button.

      These options are always available from the profile menu in the header.
    TEXT
  end

  def fallback_text(text, _intent)
    if text.blank?
      "I didn’t quite get that. You can tap one of the suggestions below, or ask about your events, budgets, recipients, or navigation."
    else
      "I’m still a simple helper bot 🙂\n\nRight now I understand things like:\n" \
        "- Show upcoming events\n" \
        "- All upcoming events total budget\n" \
        "- Budget for a specific upcoming event\n" \
        "- Show my recipients\n" \
        "- How do I add an event / recipient?\n" \
        "- How do I see my wishlist?\n\n" \
        "You can also tap one of the suggestions below."
    end
  end
end
