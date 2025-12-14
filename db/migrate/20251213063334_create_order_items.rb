class CreateOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :ai_gift_suggestion, null: true, foreign_key: true

      t.references :recipient, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      # snapshots (so orders stay stable even if AI suggestion changes)
      t.string :title, null: false
      t.text :description
      t.string :estimated_price
      t.string :category
      t.string :image_url

      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
  end
end
