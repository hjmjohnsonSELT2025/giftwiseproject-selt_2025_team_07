class AddAiGiftSuggestionToWishlists < ActiveRecord::Migration[7.1]
  def change
    add_reference :wishlists, :ai_gift_suggestion, foreign_key: true
  end
end
