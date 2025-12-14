class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true

      t.string :status, null: false, default: "placed"
      t.datetime :placed_at
      t.datetime :delivered_at
      t.datetime :cancelled_at

      # COD: store address text (simple + works now)
      # Later you can normalize to addresses table if you want.
      t.text :delivery_address
      t.string :delivery_phone
      t.text :delivery_note

      t.timestamps
    end

    add_index :orders, :status
  end
end
