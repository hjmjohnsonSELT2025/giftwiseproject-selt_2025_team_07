class CreateCartItems < ActiveRecord::Migration[7.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :ai_gift_suggestion, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end

    add_index :cart_items, [:cart_id, :ai_gift_suggestion_id], unique: true
  end
end
