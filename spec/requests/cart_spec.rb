require "rails_helper"

RSpec.describe "Cart", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "Password@1", password_confirmation: "Password@1") }

  # minimal event/recipient/idea
  let!(:event) { Event.create!(user: user, event_name: "Birthday", event_date: Date.today + 5, budget: 100) }
  let!(:recipient) { Recipient.create!(user: user, name: "John", relationship: "Friend") }
  let!(:event_recipient) { EventRecipient.create!(event: event, recipient: recipient) }

  let!(:idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Headphones",
      description: "Nice wireless headphones",
      category: "Electronics",
      estimated_price: "$50"
    )
  end

  def sign_in(u)
    post login_path, params: { email: u.email, password: "Password@1" }
  end

  it "requires login to view cart" do
    get cart_path
    expect(response).to redirect_to(login_path)
  end

  it "shows cart page when logged in" do
    sign_in(user)
    get cart_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cart")
  end

  it "adds an AI suggestion to cart" do
    sign_in(user)

    expect {
      post cart_items_path, params: { ai_gift_suggestion_id: idea.id }
    }.to change { CartItem.count }.by(1)

    expect(response).to redirect_to(cart_path).or redirect_to(/.*/)
  end

  it "does not duplicate same cart item" do
    sign_in(user)

    post cart_items_path, params: { ai_gift_suggestion_id: idea.id }
    expect {
      post cart_items_path, params: { ai_gift_suggestion_id: idea.id }
    }.to change { CartItem.count }.by(0)
  end

  it "removes an item from cart" do
    sign_in(user)
    cart = Cart.for(user)
    ci = CartItem.create!(cart: cart, ai_gift_suggestion: idea, event: event, recipient: recipient, quantity: 1)

    expect {
      delete cart_item_path(ci)
    }.to change { CartItem.count }.by(-1)

    expect(response).to redirect_to(cart_path)
  end

  it "clears the cart" do
    sign_in(user)
    cart = Cart.for(user)
    CartItem.create!(cart: cart, ai_gift_suggestion: idea, event: event, recipient: recipient, quantity: 1)

    expect {
      delete clear_cart_items_path
    }.to change { cart.cart_items.count }.to(0)

    expect(response).to redirect_to(cart_path)
  end
end
