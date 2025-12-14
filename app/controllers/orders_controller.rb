class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :cancel, :deliver]

  def index
    @orders = current_user.orders.includes(order_items: [:event, :recipient]).newest_first

    @selected_event_id = params[:event_id].presence
    @selected_recipient_id = params[:recipient_id].presence
    @selected_status = params[:status].presence_in(Order::STATUSES)

    if @selected_event_id
      @orders = @orders.joins(:order_items).where(order_items: { event_id: @selected_event_id }).distinct
    end
    if @selected_recipient_id
      @orders = @orders.joins(:order_items).where(order_items: { recipient_id: @selected_recipient_id }).distinct
    end
    @orders = @orders.where(status: @selected_status) if @selected_status

    @events = Event.where(id: current_user.orders.joins(:order_items).select("order_items.event_id")).distinct.order(:event_name)
    @recipients = Recipient.where(id: current_user.orders.joins(:order_items).select("order_items.recipient_id")).distinct.order(:name)
  end

  def show
    @group_by = params[:group_by].presence_in(%w[recipient event]) || "recipient"
    @items = @order.order_items.includes(:event, :recipient).order(created_at: :desc)
  end

  # COD checkout
  def create
    cart = Cart.for(current_user)
    items = cart.cart_items.includes(:ai_gift_suggestion)

    if items.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    order = current_user.orders.create!(
      status: "placed",
      placed_at: Time.current,
      delivery_address: params[:delivery_address].to_s.strip.presence,
      delivery_phone: params[:delivery_phone].to_s.strip.presence,
      delivery_note: params[:delivery_note].to_s.strip.presence
    )

    items.each do |ci|
      s = ci.ai_gift_suggestion
      order.order_items.create!(
        ai_gift_suggestion: s,
        recipient_id: ci.recipient_id,
        event_id: ci.event_id,
        quantity: ci.quantity,
        title: s.title,
        description: s.description,
        estimated_price: s.estimated_price,
        category: s.category,
        image_url: s.image_url
      )
    end

    cart.cart_items.delete_all

    redirect_to order_path(order), notice: "Order placed (COD)."
  end

  def cancel
    if @order.status != "placed"
      redirect_to order_path(@order), alert: "This order cannot be cancelled."
      return
    end

    @order.update!(status: "cancelled", cancelled_at: Time.current)
    redirect_to order_path(@order), notice: "Order cancelled."
  end

  def deliver
    if @order.status != "placed"
      redirect_to order_path(@order), alert: "This order cannot be marked delivered."
      return
    end

    ActiveRecord::Base.transaction do
      @order.update!(status: "delivered", delivered_at: Time.current)

      @order.order_items.includes(:event, :recipient).find_each do |item|
        # Insert into gift_given_backlogs (FK safe)
        GiftGivenBacklog.create!(
          user_id: @order.user_id,
          event_id: item.event_id,
          recipient_id: item.recipient_id,
          gift_name: item.title,
          description: item.description,
          category: item.category,
          purchase_link: nil,
          given_on: Date.current,
          event_name: item.event&.event_name
        )

        # Update event_recipients gift_status if exists
        er = EventRecipient.find_by(
          user_id: @order.user_id,
          event_id: item.event_id,
          recipient_id: item.recipient_id
        )
        er&.update!(gift_status: "delivered")
      end
    end

    redirect_to order_path(@order), notice: "Marked as delivered and saved to Gift Given."
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end
end
