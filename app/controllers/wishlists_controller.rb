class WishlistsController < ApplicationController
  before_action :authenticate_user!

  def index
    # AI gift suggestions saved by the current user
    @wishlist_items = AiGiftSuggestion
                        .joins(:wishlists)
                        .where(wishlists: { user_id: current_user.id })
                        .includes(:event, :recipient)
                        .order("wishlists.created_at DESC")
                        .distinct
  end
end