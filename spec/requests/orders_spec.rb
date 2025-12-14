require "rails_helper"

RSpec.describe "Orders", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "test2@example.com", password: "Password@1", password_confirmation: "Password@1") }
  let!(:event) { Event.create!(user: user, event_name: "Anniversary", event_date: Date.today + 10, budget: 200) }
  let!(:recipient) { Recipient.create!(user: user, name: "Mary", relationship: "Family") }
  let!(:event_recipient) { EventRecipient.create!(event: event, recipient: recipient) }

  let!(:idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Perfume",
      description: "Great fragrance",
      category: "Beauty",
      estimated_price: "$60"
    )
  end

  def sign_in(u)
    post login_path, params: { email: u.email, password: "Password@1" }
  end

  it "requires login to view orders" do
    get orders_path
    expect(response).to redirect_to(login_path)
  end

  it "lists orders when logged in" do
    sign_in(user)
    get orders_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("My Orders")
  end

  it "creates an order from cart (COD checkout)" do
    sign_in(user)
    cart = Cart.for(user)
    CartItem.create!(cart: cart, ai_gift_suggestion: idea, event: event, recipient: recipient, quantity: 1)

    expect {
      post orders_path, params: {
        delivery_address: "123 Test St",
        delivery_phone: "+1 (222) 333-4444",
        delivery_note: "Leave at door"
      }
    }.to change { Order.count }.by(1)

    expect(response).to redirect_to(orders_path).or redirect_to(/orders\/\d+/)
  end

  it "shows an order page" do
    sign_in(user)
    order = Order.create!(user: user, status: "placed", placed_at: Time.current, delivery_address: "abc", delivery_phone: "111")

    get order_path(order)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Order ##{order.id}")
  end

  # Only if you have these routes/actions:
  it "cancels an order (if supported)" do
    sign_in(user)
    order = Order.create!(user: user, status: "placed", placed_at: Time.current, delivery_address: "abc", delivery_phone: "111")

    if Rails.application.routes.url_helpers.respond_to?(:cancel_order_path)
      patch cancel_order_path(order)
      expect(response).to redirect_to(order_path(order)).or redirect_to(/orders\/\d+/)
      order.reload
      expect(order.status).to eq("cancelled")
    end
  end

  it "marks delivered (if supported)" do
    sign_in(user)
    order = Order.create!(user: user, status: "placed", placed_at: Time.current, delivery_address: "abc", delivery_phone: "111")

    if Rails.application.routes.url_helpers.respond_to?(:deliver_order_path)
      patch deliver_order_path(order)
      expect(response).to redirect_to(order_path(order)).or redirect_to(/orders\/\d+/)
      order.reload
      expect(order.status).to eq("delivered")
    end
  end
end
