class CreateEventRecipients < ActiveRecord::Migration[7.1]
  def change
    create_table :event_recipients do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: true
      t.text :gift_ideas
      t.decimal :budget_allocated, precision: 10, scale: 2
      t.string :gift_status, default: 'planning'

      t.timestamps
    end

    add_index :event_recipients, [:event_id, :recipient_id], unique: true
    add_index :event_recipients, [:user_id, :event_id]
    add_index :event_recipients, [:user_id, :recipient_id]
  end
  def down
    drop_table :event_recipients
  end
end