class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :event_name, null: false
      t.text :description
      t.date :event_date
      t.string :location
      t.decimal :budget, precision: 10, scale: 2
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :events, [:user_id, :event_date]
  end
  def down
    drop_table :events
  end
end