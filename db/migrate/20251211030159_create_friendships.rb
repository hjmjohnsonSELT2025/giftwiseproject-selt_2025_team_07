class CreateFriendships < ActiveRecord::Migration[7.1]
  def change
    create_table :friendships do |t|
      t.integer :user_id, null: false
      t.integer :friend_id, null: false
      t.string :status, default: 'pending', null: false
      t.timestamps
    end

    add_index :friendships, [:user_id, :friend_id], unique: true
    add_index :friendships, :user_id
    add_index :friendships, :friend_id
    add_foreign_key :friendships, :users, column: :user_id
    add_foreign_key :friendships, :users, column: :friend_id
  end
end