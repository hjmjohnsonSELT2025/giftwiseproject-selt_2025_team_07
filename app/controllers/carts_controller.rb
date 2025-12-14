class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = Cart.for(current_user)

    items = @cart.cart_items.includes(:recipient, :event, :ai_gift_suggestion)

    # Filters
    @selected_event_id = params[:event_id].presence
    @selected_recipient_id = params[:recipient_id].presence
    @group_by = params[:group_by].presence_in(%w[recipient event]) || "recipient"

    items = items.where(event_id: @selected_event_id) if @selected_event_id
    items = items.where(recipient_id: @selected_recipient_id) if @selected_recipient_id

    @items = items.order(created_at: :desc)

    @events = Event.where(id: @cart.cart_items.select(:event_id)).order(:event_name)
    @recipients = Recipient.where(id: @cart.cart_items.select(:recipient_id)).order(:name)
  end
end
