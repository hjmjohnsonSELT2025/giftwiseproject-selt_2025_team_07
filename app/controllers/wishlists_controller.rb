class WishlistsController < ApplicationController
  before_action :authenticate_user!

  def index
    @wishlist_items = current_user.wishlists
                                  .includes(ai_gift_suggestion: [:event, :recipient])
                                  .order(created_at: :desc)
  end

  def move_to_cart
    wishlist = current_user.wishlists.find(params[:id])
    idea = wishlist.ai_gift_suggestion

    CartItem.find_or_create_by!(
      cart: Cart.for(current_user),
      ai_gift_suggestion: idea
    ) do |ci|
      ci.event_id = idea.event_id
      ci.recipient_id = idea.recipient_id
      ci.quantity = 1
    end

    wishlist.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to wishlists_path, notice: "Moved to cart." }
    end
  end
end