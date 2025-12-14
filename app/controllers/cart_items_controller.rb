class CartItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    cart = Cart.for(current_user)
    suggestion = AiGiftSuggestion.find(params[:ai_gift_suggestion_id])

    # Only allow if the event is accessible to current_user
    Event.accessible_to(current_user).find(suggestion.event_id)

    CartItem.find_or_create_by!(
      cart: cart,
      ai_gift_suggestion: suggestion
    ) do |ci|
      ci.recipient_id = suggestion.recipient_id
      ci.event_id = suggestion.event_id
      ci.quantity = 1
    end

    redirect_back fallback_location: cart_path, notice: "Added to cart."
  end

  def bulk_create_from_wishlist
    cart = Cart.for(current_user)

    ids = Array(params[:ai_gift_suggestion_ids]).map(&:to_i).uniq
    suggestions = AiGiftSuggestion
                    .joins(:wishlists)
                    .where(id: ids, wishlists: { user_id: current_user.id })
                    .includes(:event, :recipient)

    created = 0
    suggestions.each do |s|
      item = CartItem.find_or_create_by(cart: cart, ai_gift_suggestion: s) do |ci|
        ci.recipient_id = s.recipient_id
        ci.event_id = s.event_id
        ci.quantity = 1
      end
      created += 1 if item.persisted?
    end

    redirect_to cart_path, notice: "Added #{created} item(s) to cart."
  end

  def destroy
    cart = Cart.for(current_user)
    item = cart.cart_items.find(params[:id])
    item.destroy
    redirect_to cart_path, notice: "Removed from cart."
  end

  def clear
    cart = Cart.for(current_user)
    cart.cart_items.delete_all
    redirect_to cart_path, notice: "Cart cleared."
  end
end
