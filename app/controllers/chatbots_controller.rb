# app/controllers/chatbots_controller.rb
class ChatbotsController < ApplicationController
  before_action :authenticate_user!

  def message
    session[:chatbot_history] ||= []
    session[:chatbot_mode]    ||= "main"  # "main" or "nav"
    @custom_quick_replies       = nil

    if params[:command].present?
      handle_command(params[:command])
    else
      handle_message
    end

    render json: {
      messages:      session[:chatbot_history],
      quick_replies: current_quick_replies
    }
  rescue => e
    Rails.logger.error("Chatbot MESSAGE error: #{e.class} - #{e.message}")
    render json: {
      messages:      session[:chatbot_history] || [],
      quick_replies: main_quick_replies
    }, status: :internal_server_error
  end

  private

  # ---------- Commands (reload / exit) ----------

  def handle_command(command)
    case command
    when "reset"
      session[:chatbot_history] = [
        bot_msg(
          "Conversation restarted ✅\n\n" \
            "Hi again! I can help with upcoming events, recipients, wishlist and budgets.\n" \
            "Tap one of the suggestions below to get started."
        )
      ]
      session[:chatbot_mode] = "main"

    when "exit"
      session[:chatbot_history] = []
      session[:chatbot_mode]    = "main"
    end
  end

  # ---------- Normal messages ----------

  def handle_message
    text   = params[:text].to_s.strip
    intent = params[:intent].presence

    return if text.blank? && intent.blank?

    session[:chatbot_history] << user_msg(text) if text.present?

    bot_text =
      if intent.present?
        respond_to_intent(intent)
      else
        respond_to_free_text(text)
      end

    session[:chatbot_history] << bot_msg(bot_text) if bot_text.present?
  end

  # ---------- Intent routing ----------

  def respond_to_intent(intent)
    # menu switching
    case intent
    when "nav_menu"
      session[:chatbot_mode] = "nav"
      return nav_menu_text
    when "main_menu"
      session[:chatbot_mode] = "main"
      return main_menu_text
    end

    # Single event budget pick like "budget_event_12"
    if intent.start_with?("budget_event_")
      event_id = intent.split("budget_event_").last.to_i
      return single_event_budget_breakdown(event_id)
    end

    case intent
    when "summary_upcoming_events"
      upcoming_events_summary

    when "summary_recipients"
      recipients_summary

    when "summary_wishlist"
      wishlist_summary

      # budgets
    when "summary_budgets_per_event"
      safe_upcoming_events_per_event_budget

    when "budget_single_event"
      prompt_choose_event_for_budget

      # navigation
    when "nav_add_event"       then nav_add_event
    when "nav_link_recipients" then nav_link_recipients
    when "nav_add_recipient"   then nav_add_recipient
    when "nav_edit_recipient"  then nav_edit_recipient
    when "nav_view_wishlist"   then nav_view_wishlist
    when "nav_edit_profile"    then nav_edit_profile
    when "nav_change_password" then nav_change_password
    when "nav_view_events"     then nav_view_events
    when "nav_view_recipients" then nav_view_recipients

    else
      "Hmm, I didn’t understand that option. " \
        "Try another quick action or tap *Back to main menu*."
    end
  end

  # ---------- Free-text routing ----------

  def respond_to_free_text(text)
    down = text.downcase

    # data
    if down.include?("budget") && down.include?("single") && down.include?("event")
      prompt_choose_event_for_budget
    elsif down.include?("budget") && (down.include?("upcoming") || down.include?("all events"))
      safe_upcoming_events_per_event_budget
    elsif down.include?("upcoming events")
      upcoming_events_summary
    elsif down.include?("recipient")
      recipients_summary
    elsif down.include?("wishlist")
      wishlist_summary

      # navigation
    elsif down.include?("how do i add an event")
      nav_add_event
    elsif down.include?("link recipients") || down.include?("link a recipient")
      nav_link_recipients
    elsif down.include?("add a recipient") || down.include?("create a recipient")
      nav_add_recipient
    elsif down.include?("edit recipient")
      nav_edit_recipient
    elsif down.include?("edit profile")
      nav_edit_profile
    elsif down.include?("change password")
      nav_change_password
    elsif down.include?("all events")
      nav_view_events
    elsif down.include?("all recipients")
      nav_view_recipients
    else
      main_menu_text
    end
  end

  # ---------- Quick replies ----------

  def current_quick_replies
    return @custom_quick_replies if @custom_quick_replies.present?

    if session[:chatbot_mode] == "nav"
      navigation_quick_replies
    else
      main_quick_replies
    end
  end

  def main_quick_replies
    [
      { label: "Upcoming events",              intent: "summary_upcoming_events" },
      { label: "My recipients",                intent: "summary_recipients" },
      { label: "Wishlist overview",            intent: "summary_wishlist" },
      { label: "Budget: all upcoming events",  intent: "summary_budgets_per_event" },
      { label: "Budget: single event",         intent: "budget_single_event" },
      { label: "Navigation help",              intent: "nav_menu" }
    ]
  end

  def navigation_quick_replies
    [
      { label: "How do I add an event?",           intent: "nav_add_event" },
      { label: "How do I link recipients?",        intent: "nav_link_recipients" },
      { label: "How do I add a recipient?",        intent: "nav_add_recipient" },
      { label: "How do I edit a recipient?",       intent: "nav_edit_recipient" },
      { label: "How do I view my wishlist?",       intent: "nav_view_wishlist" },
      { label: "How do I edit my profile?",        intent: "nav_edit_profile" },
      { label: "How do I change my password?",     intent: "nav_change_password" },
      { label: "How do I see all events?",         intent: "nav_view_events" },
      { label: "How do I see all recipients?",     intent: "nav_view_recipients" },
      { label: "Back to main menu",                intent: "main_menu" }
    ]
  end

  # ---------- Shared scopes ----------

  def upcoming_events_scope
    @upcoming_events_scope ||= current_user
                                 .events
                                 .where("event_date >= ?", Date.today)
                                 .order(:event_date)
  end

  def event_recipient_scope(event_id)
    EventRecipient
      .includes(:recipient)
      .where(user_id: current_user.id, event_id: event_id)
  end

  # ---------- DATA ANSWERS ----------

  # 1) Upcoming events summary list
  def upcoming_events_summary
    events = upcoming_events_scope

    if events.empty?
      "You don’t have any upcoming events yet.\n\n" \
        "From the dashboard, click **+ Add Event** to create your first event."
    else
      lines = events.limit(5).map do |e|
        date   = e.event_date&.strftime("%b %-d, %Y")
        budget =
          if e.budget.present?
            "$#{e.budget.to_i}"
          else
            "no budget set"
          end
        "• #{e.event_name} on #{date} — #{budget}"
      end
      more = events.count > 5 ? "\n…plus #{events.count - 5} more event(s)." : ""
      "Here are your upcoming events:\n\n#{lines.join("\n")}#{more}"
    end
  end

  # 2) Helper wrapper so failures don’t kill the button
  def safe_upcoming_events_per_event_budget
    upcoming_events_per_event_budget
  rescue => e
    Rails.logger.error("Chatbot budget-all error: #{e.class} - #{e.message}")
    "I had trouble calculating budgets right now 😅. Please try again in a moment."
  end

  # Budget for ALL upcoming events: per event + total
  def upcoming_events_per_event_budget
    events = upcoming_events_scope

    if events.empty?
      return "You don’t have any upcoming events yet, so there are no upcoming budgets."
    end

    lines = []
    grand = 0.0

    events.each do |e|
      allocated = event_recipient_scope(e.id).sum(:budget_allocated).to_f

      if allocated.zero? && e.budget.present?
        allocated = e.budget.to_f
      end

      grand += allocated
      date_label = e.event_date&.strftime("%b %-d, %Y") || "no date"
      lines << "• #{e.event_name} (#{date_label}) — $#{allocated.round(2)}"
    end

    "Here’s the budget for your upcoming events:\n\n" \
      "#{lines.join("\n")}\n\n" \
      "Total planned budget across these events: **$#{grand.round(2)}**."
  end

  # 3) Ask user to pick ONE upcoming event for detailed breakdown
  def prompt_choose_event_for_budget
    events = upcoming_events_scope

    if events.empty?
      return "You don’t have any upcoming events yet, so there’s nothing to break down.\n\n" \
        "Start by creating an event from the dashboard."
    end

    @custom_quick_replies =
      events.map do |e|
        label = if e.event_date.present?
                  "#{e.event_name} (#{e.event_date.strftime('%b %-d')})"
                else
                  e.event_name
                end
        { label: label, intent: "budget_event_#{e.id}" }
      end + [{ label: "Back to main menu", intent: "main_menu" }]

    "Choose an event below to see a budget breakdown by recipient."
  end



  # 4) Detailed budget for a single event (per recipient)
  def single_event_budget_breakdown(event_id)
    event = current_user.events.find_by(id: event_id)
    return "I couldn’t find that event anymore. Please choose again." unless event

    ers = event_recipient_scope(event.id)

    if ers.empty?
      if event.budget.present?
        return "For **#{event.event_name}**, no recipient-specific budgets are set yet.\n\n" \
          "The overall event budget is **$#{event.budget.to_i}**.\n" \
          "You can allocate budgets per recipient on the event details page."
      else
        return "For **#{event.event_name}**, there are no recipient budgets and no overall budget set yet."
      end
    end

    # Do we actually have per-recipient allocations?
    any_allocated = ers.any? { |er| er.budget_allocated.present? && er.budget_allocated.to_f > 0 }

    if !any_allocated
      # Only event-level budget is used
      if event.budget.present?
        "For **#{event.event_name}**, you haven’t set budgets per recipient yet.\n\n" \
          "The total budget for this event is **$#{event.budget.to_i}**.\n" \
          "Once you allocate amounts per recipient, I’ll show a detailed breakdown here."
      else
        "For **#{event.event_name}**, there are recipients but no budgets have been set yet."
      end
    else
      lines = ers.map do |er|
        name = er.recipient&.name || "Recipient ##{er.recipient_id}"
        amt  = er.budget_allocated.to_f
        label_amt = amt.positive? ? "$#{amt.to_i}" : "not set"
        "• #{name} — #{label_amt}"
      end

      total = ers.sum(:budget_allocated).to_f
      total = event.budget.to_f if total.zero? && event.budget.present?

      "Budget breakdown for **#{event.event_name}**:\n\n" \
        "#{lines.join("\n")}\n\n" \
        "Total for this event: **$#{total.to_i}**."
    end
  end





  # 5) Recipient summary
  def recipients_summary
    recs = current_user.recipients.order(:name)

    if recs.empty?
      "You don’t have any recipients yet.\n\n" \
        "From the dashboard, click the **Recipients** card then **New Recipient** to add someone."
    else
      names = recs.limit(8).map { |r| "• #{r.name}" }.join("\n")
      more  = recs.count > 8 ? "\n…plus #{recs.count - 8} more recipient(s)." : ""
      "You currently have #{recs.count} recipient(s):\n\n#{names}#{more}"
    end
  end

  # 6) Wishlist overview
  def wishlist_summary
    items = Wishlist.where(user_id: current_user.id)

    if items.empty?
      "Your wishlist is empty.\n\n" \
        "When you save gift ideas, they’ll appear on the **Wishlist** page (heart icon in the header)."
    else
      grouped = items.includes(:recipient).group_by(&:recipient)

      lines = grouped.map do |recipient, rec_items|
        name = recipient&.name || "Unassigned recipient"
        "• #{name}: #{rec_items.size} item(s)"
      end

      "Here’s a quick wishlist overview:\n\n#{lines.join("\n")}"
    end
  end

  # ---------- NAVIGATION ANSWERS ----------

  def nav_menu_text
    "Navigation help:\n\n" \
      "• How to add events\n" \
      "• How to link recipients to events\n" \
      "• How to add / edit recipients\n" \
      "• How to view wishlist, edit profile, or change password\n\n" \
      "Tap one of the navigation questions below, or **Back to main menu** to return."
  end

  def nav_add_event
    "To add an event:\n" \
      "1. From the **Dashboard**, click the **Events** card or the **+ Add Event** button.\n" \
      "2. Fill in the event name, date, budget and other details.\n" \
      "3. Click **Create Event** to save it."
  end

  def nav_link_recipients
    "To link recipients to an event:\n" \
      "1. Open the event (from **Dashboard > Events** or the **All Events** page).\n" \
      "2. In the event details screen, find the **Recipients** / **Add Recipient** section.\n" \
      "3. Select one or more recipients and save.\n" \
      "After that, budgets and gift ideas can be tracked per recipient for that event."
  end

  def nav_add_recipient
    "To add a recipient:\n" \
      "1. From the **Dashboard**, click the **Recipients** card or the **New Recipient** button.\n" \
      "2. Enter their name (required) plus any optional details.\n" \
      "3. Click **Create Recipient** to save."
  end

  def nav_edit_recipient
    "To edit a recipient:\n" \
      "1. Go to the **Recipients** page.\n" \
      "2. Click on a recipient row or use the **Edit** button.\n" \
      "3. Update the details and click **Update Recipient**."
  end

  def nav_view_wishlist
    "To view your wishlist:\n" \
      "1. Click the **heart icon** in the top header, or open the **Wishlist** page.\n" \
      "2. You’ll see saved gift ideas grouped by recipient."
  end

  def nav_edit_profile
    "To edit your profile:\n" \
      "1. Click the **profile icon** in the top-right corner.\n" \
      "2. Choose **Edit Profile**.\n" \
      "3. Update your information and save."
  end

  def nav_change_password
    "To change your password:\n" \
      "1. Click the **profile icon** in the top-right corner.\n" \
      "2. Select **Change password**.\n" \
      "3. Enter your current password and new password, then save."
  end

  def nav_view_events
    "To see all events:\n" \
      "1. From the **Dashboard**, click the **Events** card or the **View all** link under Upcoming Events.\n" \
      "2. You’ll see a list of upcoming and past events."
  end

  def nav_view_recipients
    "To see all recipients:\n" \
      "1. From the **Dashboard**, click the **Recipients** card.\n" \
      "2. This opens the Recipients page with your full list."
  end

  def main_menu_text
    "Here’s what I can help with right now:\n\n" \
      "• Show **upcoming events**, **recipients**, **wishlist**\n" \
      "• Show **budget for all upcoming events** or **budget for a single event**\n" \
      "• Help you navigate: adding events, linking recipients, editing profile, etc.\n\n" \
      "Tap one of the suggestions below, or ask your question in your own words."
  end

  # ---------- Helpers for storing messages ----------

  def user_msg(text)
    { "role" => "user", "text" => text.to_s }
  end

  def bot_msg(text)
    { "role" => "bot", "text" => text.to_s }
  end
end
