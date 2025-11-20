class WishlistsController < ApplicationController
  # add any auth filter you use here, e.g.:
  # before_action :require_login

  def index
    @wishlist_items =
      current_user
        .ai_gift_suggestions
        .where(saved_to_wishlist: true)
        .includes(:event, :recipient)
        .order(created_at: :desc)
  end
end
